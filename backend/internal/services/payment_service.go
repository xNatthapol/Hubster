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
	GetPaymentRecordDetails(ctx context.Context, paymentRecordID uint, accessorUserID uint, isHostAction bool) (*models.PaymentRecordResponse, error)
	ApprovePaymentProof(ctx context.Context, hostUserID uint, paymentRecordID uint) (*models.PaymentRecordResponse, error)
	DeclinePaymentProof(ctx context.Context, hostUserID uint, paymentRecordID uint) (*models.PaymentRecordResponse, error)
	ListPaymentRecordsForMembership(ctx context.Context, memberUserID uint, membershipID uint) ([]models.PaymentRecord, error)
	ListPaymentRecordsForHost(ctx context.Context, hostUserID uint, hostedSubscriptionID uint, statusFilter models.PaymentRecordStatus) ([]models.PaymentRecordResponse, error)
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
func (s *paymentService) ListPaymentRecordsForHost(ctx context.Context, hostUserID uint, hostedSubscriptionID uint, statusFilter models.PaymentRecordStatus) ([]models.PaymentRecordResponse, error) {
	hs, err := s.hsRepo.GetByID(ctx, hostedSubscriptionID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSubscriptionNotFound
		}
		return nil, fmt.Errorf("fetching hosted subscription for ownership check: %w", err)
	}
	if hs.HostUserID != hostUserID {
		return nil, ErrForbidden
	}

	dbRecords, err := s.paymentRecordRepo.ListByHostedSubscriptionIDAndStatus(ctx, hostedSubscriptionID, statusFilter)
	if err != nil {
		return nil, fmt.Errorf("fetching payment records from repo: %w", err)
	}

	responses := make([]models.PaymentRecordResponse, len(dbRecords))
	for i, pr := range dbRecords {

		var memberName string
		var memberAvatar *string
		if pr.SubscriptionMembership.User.ID != 0 {
			memberName = pr.SubscriptionMembership.User.FullName
			memberAvatar = pr.SubscriptionMembership.User.ProfilePictureURL
		} else {
			log.Printf("Warning: Member User not fully preloaded for PaymentRecord ID %d (MembershipID: %d)", pr.ID, pr.SubscriptionMembershipID)
			memberName = fmt.Sprintf("Member ID %d", pr.SubscriptionMembership.MemberUserID)
		}

		var subTitle string
		if pr.SubscriptionMembership.HostedSubscription.ID != 0 {
			subTitle = pr.SubscriptionMembership.HostedSubscription.SubscriptionTitle
		} else {
			log.Printf("Warning: HostedSubscription not preloaded for PaymentRecord ID %d (MembershipID: %d)", pr.ID, pr.SubscriptionMembershipID)
			subTitle = fmt.Sprintf("Subscription ID %d", pr.SubscriptionMembership.HostedSubscriptionID)
		}

		responses[i] = models.PaymentRecordResponse{
			ID:                       pr.ID,
			CreatedAt:                pr.CreatedAt,
			UpdatedAt:                pr.UpdatedAt,
			SubscriptionMembershipID: pr.SubscriptionMembershipID,
			PaymentCycleIdentifier:   pr.PaymentCycleIdentifier,
			AmountExpected:           pr.AmountExpected,
			AmountPaid:               pr.AmountPaid,
			PaymentMethod:            pr.PaymentMethod,
			TransactionReference:     pr.TransactionReference,
			ProofImageURL:            pr.ProofImageURL,
			SubmittedAt:              pr.SubmittedAt,
			Status:                   pr.Status,
			ReviewedByUserID:         pr.ReviewedByUserID,
			ReviewedAt:               pr.ReviewedAt,
			MemberName:               memberName,
			MemberProfilePictureURL:  memberAvatar,
			SubscriptionTitle:        subTitle,
		}
	}
	return responses, nil
}

// GetPaymentRecordDetails retrieves a specific payment record.
func (s *paymentService) GetPaymentRecordDetails(ctx context.Context, paymentRecordID uint, accessorUserID uint, isHostAction bool) (*models.PaymentRecordResponse, error) {
	pr, err := s.paymentRecordRepo.GetByID(ctx, paymentRecordID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrPaymentRecordNotFound
		}
		return nil, fmt.Errorf("fetching payment record from repo: %w", err)
	}

	isMember := pr.SubscriptionMembership.MemberUserID == accessorUserID
	isHost := pr.SubscriptionMembership.HostedSubscription.HostUserID == accessorUserID

	if !isMember && !isHost {
		return nil, ErrForbidden
	}

	// Map to PaymentRecordResponse DTO
	var memberName string
	var memberAvatar *string
	if pr.SubscriptionMembership.User.ID != 0 {
		memberName = pr.SubscriptionMembership.User.FullName
		memberAvatar = pr.SubscriptionMembership.User.ProfilePictureURL
	} else {
		memberName = "Member (Details Missing)"
	}

	var subTitle string
	if pr.SubscriptionMembership.HostedSubscription.ID != 0 {
		subTitle = pr.SubscriptionMembership.HostedSubscription.SubscriptionTitle
	} else {
		subTitle = "Subscription (Details Missing)"
	}

	response := &models.PaymentRecordResponse{
		ID:                       pr.ID,
		CreatedAt:                pr.CreatedAt,
		UpdatedAt:                pr.UpdatedAt,
		SubscriptionMembershipID: pr.SubscriptionMembershipID,
		PaymentCycleIdentifier:   pr.PaymentCycleIdentifier,
		AmountExpected:           pr.AmountExpected,
		AmountPaid:               pr.AmountPaid,
		PaymentMethod:            pr.PaymentMethod,
		TransactionReference:     pr.TransactionReference,
		ProofImageURL:            pr.ProofImageURL,
		SubmittedAt:              pr.SubmittedAt,
		Status:                   pr.Status,
		ReviewedByUserID:         pr.ReviewedByUserID,
		ReviewedAt:               pr.ReviewedAt,
		MemberName:               memberName,
		MemberProfilePictureURL:  memberAvatar,
		SubscriptionTitle:        subTitle,
	}
	return response, nil
}

// ApprovePaymentProof allows a host to approve a payment proof.
func (s *paymentService) ApprovePaymentProof(ctx context.Context, hostUserID uint, paymentRecordID uint) (*models.PaymentRecordResponse, error) {
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

	updatedPRFull, fetchErr := s.paymentRecordRepo.GetByID(ctx, paymentRecordID)
	if fetchErr != nil {
		return nil, fmt.Errorf("re-fetching payment record after approval: %w", fetchErr)
	}
	// Map using the same logic as GetPaymentRecordDetails
	var memberName string
	var memberAvatar *string
	var subTitle string
	if updatedPRFull.SubscriptionMembership.ID != 0 {
		if updatedPRFull.SubscriptionMembership.User.ID != 0 {
			memberName = updatedPRFull.SubscriptionMembership.User.FullName
			memberAvatar = updatedPRFull.SubscriptionMembership.User.ProfilePictureURL
		}
		if updatedPRFull.SubscriptionMembership.HostedSubscription.ID != 0 {
			subTitle = updatedPRFull.SubscriptionMembership.HostedSubscription.SubscriptionTitle
		}
	}
	response := &models.PaymentRecordResponse{
		ID: updatedPRFull.ID, CreatedAt: updatedPRFull.CreatedAt, UpdatedAt: updatedPRFull.UpdatedAt, SubscriptionMembershipID: updatedPRFull.SubscriptionMembershipID, PaymentCycleIdentifier: updatedPRFull.PaymentCycleIdentifier,
		AmountExpected: updatedPRFull.AmountExpected, AmountPaid: updatedPRFull.AmountPaid, PaymentMethod: updatedPRFull.PaymentMethod, TransactionReference: updatedPRFull.TransactionReference,
		ProofImageURL: updatedPRFull.ProofImageURL, SubmittedAt: updatedPRFull.SubmittedAt, Status: updatedPRFull.Status, ReviewedByUserID: updatedPRFull.ReviewedByUserID, ReviewedAt: updatedPRFull.ReviewedAt,
		MemberName: memberName, MemberProfilePictureURL: memberAvatar, SubscriptionTitle: subTitle,
	}
	return response, nil
}

// DeclinePaymentProof allows a host to decline a payment proof.
func (s *paymentService) DeclinePaymentProof(ctx context.Context, hostUserID uint, paymentRecordID uint) (*models.PaymentRecordResponse, error) {
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
	updatedPRFull, fetchErr := s.paymentRecordRepo.GetByID(ctx, paymentRecordID)
	if fetchErr != nil {
		return nil, fmt.Errorf("re-fetching payment record after decline: %w", fetchErr)
	}
	var memberName string
	var memberAvatar *string
	var subTitle string
	if updatedPRFull.SubscriptionMembership.ID != 0 {
		if updatedPRFull.SubscriptionMembership.User.ID != 0 {
			memberName = updatedPRFull.SubscriptionMembership.User.FullName
			memberAvatar = updatedPRFull.SubscriptionMembership.User.ProfilePictureURL
		}
		if updatedPRFull.SubscriptionMembership.HostedSubscription.ID != 0 {
			subTitle = updatedPRFull.SubscriptionMembership.HostedSubscription.SubscriptionTitle
		}
	}
	response := &models.PaymentRecordResponse{
		ID: updatedPRFull.ID, CreatedAt: updatedPRFull.CreatedAt, UpdatedAt: updatedPRFull.UpdatedAt, SubscriptionMembershipID: updatedPRFull.SubscriptionMembershipID, PaymentCycleIdentifier: updatedPRFull.PaymentCycleIdentifier,
		AmountExpected: updatedPRFull.AmountExpected, AmountPaid: updatedPRFull.AmountPaid, PaymentMethod: updatedPRFull.PaymentMethod, TransactionReference: updatedPRFull.TransactionReference,
		ProofImageURL: updatedPRFull.ProofImageURL, SubmittedAt: updatedPRFull.SubmittedAt, Status: updatedPRFull.Status, ReviewedByUserID: updatedPRFull.ReviewedByUserID, ReviewedAt: updatedPRFull.ReviewedAt,
		MemberName: memberName, MemberProfilePictureURL: memberAvatar, SubscriptionTitle: subTitle,
	}
	return response, nil
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
