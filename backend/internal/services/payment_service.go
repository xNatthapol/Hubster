package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/xNatthapol/hubster/internal/models"
	"github.com/xNatthapol/hubster/internal/repositories"
	"gorm.io/gorm"
	"log"
)

// Custom errors for PaymentService
var (
	ErrMembershipNotFound         = errors.New("subscription membership not found")
	ErrNotMember                  = errors.New("user is not the member of this subscription slot")
	ErrInvalidPaymentCycle        = errors.New("invalid payment cycle identifier for this membership")
	ErrPaymentAlreadyProcessed    = errors.New("a payment record for this cycle has already been processed (approved/declined)")
	ErrPaymentRecordNotFound      = errors.New("payment record not found")
	ErrPaymentRecordNotModifiable = errors.New("payment record is not in a state that can be modified by host")
)

// PaymentService defines the interface for payment-related operations.
type PaymentService interface {
	SubmitPaymentProof(ctx context.Context, memberUserID uint, membershipID uint, req *models.CreatePaymentRecordRequest) (*models.PaymentRecord, error)
	GetPaymentRecordDetails(ctx context.Context, paymentRecordID uint, accessorUserID uint, isHostAction bool) (*models.PaymentRecord, error)
	ApprovePaymentProof(ctx context.Context, hostUserID uint, paymentRecordID uint) (*models.PaymentRecord, error)
	DeclinePaymentProof(ctx context.Context, hostUserID uint, paymentRecordID uint) (*models.PaymentRecord, error)
	ListPaymentRecordsForMembership(ctx context.Context, memberUserID uint, membershipID uint) ([]models.PaymentRecord, error) // Member's history
	ListPaymentRecordsForHost(ctx context.Context, hostUserID uint, hostedSubscriptionID uint, statusFilter models.PaymentRecordStatus) ([]models.PaymentRecord, error)
}

type paymentService struct {
	paymentRecordRepo repositories.PaymentRecordRepository
	membershipRepo    repositories.SubscriptionMembershipRepository
	hsRepo            repositories.HostedSubscriptionRepository
}

// NewPaymentService creates a new PaymentService instance.
func NewPaymentService(
	prRepo repositories.PaymentRecordRepository,
	memRepo repositories.SubscriptionMembershipRepository,
	hsRepo repositories.HostedSubscriptionRepository,
) PaymentService {
	return &paymentService{
		paymentRecordRepo: prRepo,
		membershipRepo:    memRepo,
		hsRepo:            hsRepo,
	}
}

// SubmitPaymentProof allows a member to submit their proof of payment.
func (s *paymentService) SubmitPaymentProof(ctx context.Context, memberUserID uint, membershipID uint, req *models.CreatePaymentRecordRequest) (*models.PaymentRecord, error) {
	membership, err := s.membershipRepo.GetByID(ctx, membershipID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrMembershipNotFound
		}
		return nil, fmt.Errorf("fetching membership: %w", err)
	}

	if membership.MemberUserID != memberUserID {
		return nil, ErrNotMember
	}

	var amountExpected float64
	if membership.HostedSubscription.ID != 0 && membership.HostedSubscription.TotalSlots > 0 {
		amountExpected = membership.HostedSubscription.CostPerCycle / float64(membership.HostedSubscription.TotalSlots)
	} else {
		return nil, fmt.Errorf("could not determine amount expected for membership ID %d", membershipID)
	}

	paymentRecord := &models.PaymentRecord{
		SubscriptionMembershipID: membershipID,
		PaymentCycleIdentifier:   req.PaymentCycleIdentifier,
		AmountExpected:           amountExpected,
		AmountPaid:               req.AmountPaid,
		ProofImageURL:            req.ProofImageURL,
		PaymentMethod:            req.PaymentMethod,
		TransactionReference:     req.TransactionReference,
		SubmittedAt:              time.Now().UTC(),
		Status:                   models.PaymentRecordStatusProofSubmitted,
	}

	if err := s.paymentRecordRepo.Create(ctx, paymentRecord); err != nil {
		return nil, fmt.Errorf("creating payment record: %w", err)
	}

	if err := s.membershipRepo.UpdatePaymentStatus(ctx, membershipID, models.PaymentStatusProofSubmitted); err != nil {
		log.Printf("CRITICAL: Created PaymentRecord %d but failed to update SubscriptionMembership %d status to ProofSubmitted: %v",
			paymentRecord.ID, membershipID, err)
	}

	return paymentRecord, nil
}

// ListPaymentRecordsForHost retrieves payment records for a specific hosted subscription filtered by status.
func (s *paymentService) ListPaymentRecordsForHost(ctx context.Context, hostUserID uint, hostedSubscriptionID uint, statusFilter models.PaymentRecordStatus) ([]models.PaymentRecord, error) {
	hs, err := s.hsRepo.GetByID(ctx, hostedSubscriptionID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSubscriptionNotFound
		}
		return nil, fmt.Errorf("fetching hosted subscription: %w", err)
	}
	if hs.HostUserID != hostUserID {
		return nil, ErrForbidden
	}

	return s.paymentRecordRepo.ListByHostedSubscriptionIDAndStatus(ctx, hostedSubscriptionID, statusFilter)
}

// GetPaymentRecordDetails retrieves a specific payment record.
func (s *paymentService) GetPaymentRecordDetails(ctx context.Context, paymentRecordID uint, accessorUserID uint, isHostAction bool) (*models.PaymentRecord, error) {
	pr, err := s.paymentRecordRepo.GetByID(ctx, paymentRecordID) // Preloads Membership.User & Membership.HostedSubscription
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrPaymentRecordNotFound
		}
		return nil, fmt.Errorf("fetching payment record: %w", err)
	}

	// Authorization check
	if isHostAction {
		if pr.SubscriptionMembership.HostedSubscription.HostUserID != accessorUserID {
			return nil, ErrForbidden
		}
	} else {
		if pr.SubscriptionMembership.MemberUserID != accessorUserID {
			return nil, ErrForbidden
		}
	}
	return pr, nil
}

// ApprovePaymentProof allows a host to approve a payment proof.
func (s *paymentService) ApprovePaymentProof(ctx context.Context, hostUserID uint, paymentRecordID uint) (*models.PaymentRecord, error) {
	pr, err := s.paymentRecordRepo.GetByID(ctx, paymentRecordID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrPaymentRecordNotFound
		}
		return nil, fmt.Errorf("fetching payment record: %w", err)
	}

	if pr.SubscriptionMembership.HostedSubscription.HostUserID != hostUserID {
		return nil, ErrForbidden
	}

	if pr.Status != models.PaymentRecordStatusProofSubmitted {
		return nil, ErrPaymentRecordNotModifiable
	}

	err = s.paymentRecordRepo.UpdateStatus(ctx, paymentRecordID, models.PaymentRecordStatusApproved, &hostUserID)
	if err != nil {
		return nil, fmt.Errorf("updating payment record status: %w", err)
	}

	// Calculate NextPaymentDate
	var nextPaymentDate time.Time
	baseDateForNext := time.Now().UTC()
	if pr.SubscriptionMembership.NextPaymentDate != nil && !pr.SubscriptionMembership.NextPaymentDate.IsZero() {
		if pr.SubscriptionMembership.NextPaymentDate.After(baseDateForNext) {
			baseDateForNext = *pr.SubscriptionMembership.NextPaymentDate
		}
	} else {
		baseDateForNext = pr.SubscriptionMembership.JoinedDate
	}

	if pr.SubscriptionMembership.HostedSubscription.BillingCycle == models.BillingMonthly {
		nextPaymentDate = baseDateForNext.AddDate(0, 1, 0)
	} else if pr.SubscriptionMembership.HostedSubscription.BillingCycle == models.BillingAnnually {
		nextPaymentDate = baseDateForNext.AddDate(1, 0, 0)
	} else {
		log.Printf("Warning: Unknown billing cycle '%s' for membership %d",
			pr.SubscriptionMembership.HostedSubscription.BillingCycle, pr.SubscriptionMembershipID)
		nextPaymentDate = baseDateForNext.AddDate(0, 1, 0)
	}
	nextPaymentDatePtr := &nextPaymentDate

	err = s.membershipRepo.UpdatePaymentAndNextDueDate(ctx, pr.SubscriptionMembershipID, models.PaymentStatusPaid, nextPaymentDatePtr)
	if err != nil {
		log.Printf("CRITICAL: Approved PaymentRecord %d but failed to update SubscriptionMembership %d status/next_due_date: %v", pr.ID, pr.SubscriptionMembershipID, err)
	}

	return s.paymentRecordRepo.GetByID(ctx, paymentRecordID)
}

// DeclinePaymentProof allows a host to decline a payment proof.
func (s *paymentService) DeclinePaymentProof(ctx context.Context, hostUserID uint, paymentRecordID uint) (*models.PaymentRecord, error) {
	pr, err := s.paymentRecordRepo.GetByID(ctx, paymentRecordID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrPaymentRecordNotFound
		}
		return nil, fmt.Errorf("fetching payment record: %w", err)
	}

	if pr.SubscriptionMembership.HostedSubscription.HostUserID != hostUserID {
		return nil, ErrForbidden
	}
	if pr.Status != models.PaymentRecordStatusProofSubmitted {
		return nil, ErrPaymentRecordNotModifiable
	}

	err = s.paymentRecordRepo.UpdateStatus(ctx, paymentRecordID, models.PaymentRecordStatusDeclined, &hostUserID)
	if err != nil {
		return nil, fmt.Errorf("updating payment record status: %w", err)
	}

	err = s.membershipRepo.UpdatePaymentStatus(ctx, pr.SubscriptionMembershipID, models.PaymentStatusDue)
	if err != nil {
		log.Printf("CRITICAL: Declined PaymentRecord %d but failed to update SubscriptionMembership %d status: %v", pr.ID, pr.SubscriptionMembershipID, err)
	}
	return s.paymentRecordRepo.GetByID(ctx, paymentRecordID)
}

// ListPaymentRecordsForMembership retrieves payment history for a member's specific subscription.
func (s *paymentService) ListPaymentRecordsForMembership(ctx context.Context, memberUserID uint, membershipID uint) ([]models.PaymentRecord, error) {
	membership, err := s.membershipRepo.GetByID(ctx, membershipID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrMembershipNotFound
		}
		return nil, err
	}
	if membership.MemberUserID != memberUserID {
		return nil, ErrForbidden
	}
	return s.paymentRecordRepo.ListBySubscriptionMembershipID(ctx, membershipID)
}
