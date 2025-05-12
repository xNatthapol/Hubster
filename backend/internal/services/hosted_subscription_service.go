package services

import (
	"context"
	"errors"
	"fmt"
	"github.com/xNatthapol/hubster/internal/models"
	"github.com/xNatthapol/hubster/internal/repositories"
	"gorm.io/gorm"
	"log"
	"time"
)

var (
	ErrSubscriptionNotFound   = errors.New("hosted subscription not found")
	ErrSubscriptionFull       = errors.New("subscription has no available slots")
	ErrAlreadyRequestedToJoin = errors.New("you have already sent a join request to this subscription")
	ErrAlreadyMember          = errors.New("you are already a member of this subscription")
	ErrHostCannotJoinOwn      = errors.New("host cannot request to join their own subscription")
	ErrServiceNotFound        = errors.New("specified subscription service not found")
	ErrJoinRequestNotFound    = errors.New("join request not found")
	ErrJoinRequestNotPending  = errors.New("join request is not in pending state")
	ErrCannotManageRequest    = errors.New("you are not authorized to manage this join request")
	ErrForbidden              = errors.New("forbidden: action not allowed")
)

// HostedSubscriptionService defines the interface for managing hosted subscriptions.
type HostedSubscriptionService interface {
	CreateHostedSubscription(ctx context.Context, hostUserID uint, req *models.CreateHostedSubscriptionRequest) (*models.HostedSubscriptionResponse, error)
	ListHostedSubscriptionsByUserID(ctx context.Context, hostUserID uint) ([]models.HostedSubscriptionResponse, error)
	ExploreAllHostedSubscriptions(ctx context.Context, filters *models.ExploreSubscriptionFilters, sortBy string) ([]models.HostedSubscriptionResponse, error)
	GetHostedSubscriptionDetailsByID(ctx context.Context, id uint, authenticatedUserID uint) (*models.HostedSubscriptionResponse, error)
	CreateJoinRequest(ctx context.Context, requesterUserID uint, hostedSubscriptionID uint) (*models.JoinRequest, error)
	ListJoinRequestsForHost(ctx context.Context, hostUserID uint, subscriptionID uint, statusFilter *models.JoinRequestStatus) ([]models.JoinRequest, error)
	ApproveJoinRequest(ctx context.Context, hostUserID uint, requestID uint) (*models.SubscriptionMembership, error)
	DeclineJoinRequest(ctx context.Context, hostUserID uint, requestID uint) error
	ListMyJoinRequests(ctx context.Context, requesterUserID uint) ([]models.JoinRequest, error)
	ListMyMemberships(ctx context.Context, memberUserID uint) ([]models.SubscriptionMembershipResponse, error)
	ListMembersOfSubscription(ctx context.Context, authenticatedUserID uint, hostedSubscriptionID uint) ([]models.SubscriptionMembershipResponse, error)
}

type hostedSubscriptionService struct {
	hsRepo          repositories.HostedSubscriptionRepository
	joinRequestRepo repositories.JoinRequestRepository
	membershipRepo  repositories.SubscriptionMembershipRepository
	subServiceRepo  repositories.SubscriptionServiceRepository
	userRepo        repositories.UserRepository
}

// NewHostedSubscriptionService creates a new HostedSubscriptionService.
func NewHostedSubscriptionService(
	hsRepo repositories.HostedSubscriptionRepository,
	joinRequestRepo repositories.JoinRequestRepository,
	membershipRepo repositories.SubscriptionMembershipRepository,
	subServiceRepo repositories.SubscriptionServiceRepository,
	userRepo repositories.UserRepository,
) HostedSubscriptionService {
	return &hostedSubscriptionService{
		hsRepo:          hsRepo,
		joinRequestRepo: joinRequestRepo,
		membershipRepo:  membershipRepo,
		subServiceRepo:  subServiceRepo,
		userRepo:        userRepo,
	}
}

// CreateHostedSubscription
func (s *hostedSubscriptionService) CreateHostedSubscription(ctx context.Context, hostUserID uint, req *models.CreateHostedSubscriptionRequest) (*models.HostedSubscriptionResponse, error) {
	_, err := s.subServiceRepo.GetByID(ctx, req.SubscriptionServiceID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrServiceNotFound
		}
		return nil, fmt.Errorf("validating subscription service ID: %w", err)
	}

	hsDB := &models.HostedSubscription{
		HostUserID:            hostUserID,
		SubscriptionServiceID: req.SubscriptionServiceID,
		SubscriptionTitle:     req.SubscriptionTitle,
		PlanDetails:           req.PlanDetails,
		TotalSlots:            req.TotalSlots,
		CostPerCycle:          req.CostPerCycle,
		BillingCycle:          req.BillingCycle,
		PaymentQRCodeURL:      req.PaymentQRCodeURL,
		Description:           req.Description,
	}

	if err := s.hsRepo.Create(ctx, hsDB); err != nil {
		return nil, fmt.Errorf("failed to create hosted subscription in repository: %w", err)
	}

	fullHs, err := s.hsRepo.GetByID(ctx, hsDB.ID)
	if err != nil {
		log.Printf("Warning: HostedSubscription %d created, but failed to fetch full details for response: %v", hsDB.ID, err)
		return nil, fmt.Errorf("failed to retrieve created hosted subscription for response mapping")
	}

	mappedSubs := s.mapDbSubsToResponseSubs(ctx, []models.HostedSubscription{*fullHs})
	if len(mappedSubs) == 0 {
		return nil, fmt.Errorf("failed to map created hosted subscription to response")
	}
	return &mappedSubs[0], nil
}

// ListHostedSubscriptionsByUserID
func (s *hostedSubscriptionService) ListHostedSubscriptionsByUserID(ctx context.Context, hostUserID uint) ([]models.HostedSubscriptionResponse, error) {
	dbSubscriptions, err := s.hsRepo.ListByHostID(ctx, hostUserID)
	if err != nil {
		return nil, fmt.Errorf("failed to list hosted subscriptions by user ID: %w", err)
	}
	return s.mapDbSubsToResponseSubs(ctx, dbSubscriptions), nil
}

// ExploreAllHostedSubscriptions retrieves a list of all hosted subscriptions with filters and sorting.
func (s *hostedSubscriptionService) ExploreAllHostedSubscriptions(ctx context.Context, filters *models.ExploreSubscriptionFilters, sortBy string) ([]models.HostedSubscriptionResponse, error) {
	dbSubscriptions, err := s.hsRepo.ListFiltered(ctx, filters, sortBy)
	if err != nil {
		return nil, fmt.Errorf("failed to explore hosted subscriptions: %w", err)
	}
	return s.mapDbSubsToResponseSubs(ctx, dbSubscriptions), nil
}

// GetHostedSubscriptionDetailsByID
func (s *hostedSubscriptionService) GetHostedSubscriptionDetailsByID(ctx context.Context, id uint, authenticatedUserID uint) (*models.HostedSubscriptionResponse, error) {
	dbSub, err := s.hsRepo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get subscription details: %w", err)
	}
	responseSubs := s.mapDbSubsToResponseSubs(ctx, []models.HostedSubscription{*dbSub})
	if len(responseSubs) == 0 {
		return nil, fmt.Errorf("failed to map subscription details")
	}
	return &responseSubs[0], nil
}

// CreateJoinRequest handles the logic for a user requesting to join a subscription.
func (s *hostedSubscriptionService) CreateJoinRequest(ctx context.Context, requesterUserID uint, hostedSubscriptionID uint) (*models.JoinRequest, error) {
	hostedSub, err := s.hsRepo.GetByID(ctx, hostedSubscriptionID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSubscriptionNotFound
		}
		return nil, fmt.Errorf("fetching hosted subscription: %w", err)
	}

	if hostedSub.HostUserID == requesterUserID {
		return nil, ErrHostCannotJoinOwn
	}

	_, err = s.membershipRepo.FindByUserAndSubscription(ctx, requesterUserID, hostedSubscriptionID)
	if err == nil {
		return nil, ErrAlreadyMember
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("checking existing membership: %w", err)
	}

	_, err = s.joinRequestRepo.FindPendingByRequesterAndSubscription(ctx, requesterUserID, hostedSubscriptionID)
	if err == nil {
		return nil, ErrAlreadyRequestedToJoin
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("checking existing join request: %w", err)
	}

	currentMembersCount := len(hostedSub.Memberships)
	if (currentMembersCount + 1) >= hostedSub.TotalSlots {
		return nil, ErrSubscriptionFull
	}

	joinReq := &models.JoinRequest{
		RequesterUserID:      requesterUserID,
		HostedSubscriptionID: hostedSubscriptionID,
		RequestDate:          time.Now().Local(),
		Status:               models.JoinRequestStatusPending,
	}

	if err := s.joinRequestRepo.Create(ctx, joinReq); err != nil {
		return nil, fmt.Errorf("creating join request: %w", err)
	}

	fullJoinRequest, err := s.joinRequestRepo.GetByID(ctx, joinReq.ID)
	if err != nil {
		log.Printf("Warning: JoinRequest %d created, but failed to fetch its full details for response: %v", joinReq.ID, err)
		return joinReq, nil
	}

	return fullJoinRequest, nil
}

// ListJoinRequestsForHost retrieves join requests for a specific subscription owned by the host.
func (s *hostedSubscriptionService) ListJoinRequestsForHost(ctx context.Context, hostUserID uint, subscriptionID uint, statusFilter *models.JoinRequestStatus) ([]models.JoinRequest, error) {
	hostedSub, err := s.hsRepo.GetByID(ctx, subscriptionID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSubscriptionNotFound
		}
		return nil, fmt.Errorf("fetching subscription for ownership check: %w", err)
	}
	if hostedSub.HostUserID != hostUserID {
		return nil, ErrForbidden
	}

	return s.joinRequestRepo.ListBySubscriptionID(ctx, subscriptionID, statusFilter)
}

// ApproveJoinRequest allows a host to approve a pending join request.
func (s *hostedSubscriptionService) ApproveJoinRequest(ctx context.Context, hostUserID uint, requestID uint) (*models.SubscriptionMembership, error) {
	joinReq, err := s.joinRequestRepo.GetByID(ctx, requestID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrJoinRequestNotFound
		}
		return nil, fmt.Errorf("fetching join request: %w", err)
	}

	hostedSub, err := s.hsRepo.GetByID(ctx, joinReq.HostedSubscriptionID)
	if err != nil {
		log.Printf("Error: Could not find HostedSubscription %d for JoinRequest %d", joinReq.HostedSubscriptionID, requestID)
		return nil, ErrSubscriptionNotFound
	}
	if hostedSub.HostUserID != hostUserID {
		return nil, ErrCannotManageRequest
	}

	if joinReq.Status != models.JoinRequestStatusPending {
		return nil, ErrJoinRequestNotPending
	}

	_, err = s.membershipRepo.FindByUserAndSubscription(ctx, joinReq.RequesterUserID, joinReq.HostedSubscriptionID)
	if err == nil {
		_ = s.joinRequestRepo.UpdateStatus(ctx, joinReq.ID, models.JoinRequestStatusApproved)
		return nil, ErrAlreadyMember
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("checking existing membership: %w", err)
	}

	currentMembersCount := len(hostedSub.Memberships)
	if (currentMembersCount + 1) >= hostedSub.TotalSlots {
		_ = s.joinRequestRepo.UpdateStatus(ctx, joinReq.ID, models.JoinRequestStatusDeclined)
		return nil, ErrSubscriptionFull
	}

	now := time.Now().UTC()
	var initialNextPaymentDate time.Time
	year, month, _ := now.Date()
	initialNextPaymentDate = time.Date(year, month+1, 1, 0, 0, 0, 0, now.Location()).Add(-time.Nanosecond)

	membership := &models.SubscriptionMembership{
		MemberUserID:         joinReq.RequesterUserID,
		HostedSubscriptionID: joinReq.HostedSubscriptionID,
		JoinedDate:           time.Now().UTC(),
		PaymentStatus:        models.PaymentStatusDue,
		NextPaymentDate:      &initialNextPaymentDate,
	}
	if err := s.membershipRepo.Create(ctx, membership); err != nil {
		return nil, fmt.Errorf("creating subscription membership: %w", err)
	}

	if err := s.joinRequestRepo.UpdateStatus(ctx, joinReq.ID, models.JoinRequestStatusApproved); err != nil {
		log.Printf("CRITICAL: Created membership %d but failed to update JoinRequest %d to Approved: %v", membership.ID, joinReq.ID, err)
	}

	fullMembership, fetchErr := s.membershipRepo.GetByID(ctx, membership.ID)
	if fetchErr != nil {
		log.Printf("Warning: Membership %d created/approved, but failed to fetch full details for response: %v", membership.ID, fetchErr)
		return membership, nil
	}
	return fullMembership, nil
}

// DeclineJoinRequest allows a host to decline a pending join request.
func (s *hostedSubscriptionService) DeclineJoinRequest(ctx context.Context, hostUserID uint, requestID uint) error {
	joinReq, err := s.joinRequestRepo.GetByID(ctx, requestID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrJoinRequestNotFound
		}
		return fmt.Errorf("fetching join request: %w", err)
	}

	hostedSub, err := s.hsRepo.GetByID(ctx, joinReq.HostedSubscriptionID)
	if err != nil {
		return ErrSubscriptionNotFound
	}
	if hostedSub.HostUserID != hostUserID {
		return ErrCannotManageRequest
	}

	if joinReq.Status != models.JoinRequestStatusPending {
		return ErrJoinRequestNotPending
	}

	return s.joinRequestRepo.UpdateStatus(ctx, joinReq.ID, models.JoinRequestStatusDeclined)
}

// ListMyJoinRequests retrieves all join requests made by the specified user.
func (s *hostedSubscriptionService) ListMyJoinRequests(ctx context.Context, requesterUserID uint) ([]models.JoinRequest, error) {
	requests, err := s.joinRequestRepo.ListByRequesterID(ctx, requesterUserID)
	if err != nil {
		return nil, fmt.Errorf("fetching user's join requests from repo: %w", err)
	}
	return requests, nil
}

// ListMyMemberships retrieves all subscriptions a user is a member of, enriched for display.
func (s *hostedSubscriptionService) ListMyMemberships(ctx context.Context, memberUserID uint) ([]models.SubscriptionMembershipResponse, error) {
	dbMemberships, err := s.membershipRepo.ListByUserID(ctx, memberUserID) // This preloads HostedSub.Service and Host.User
	if err != nil {
		return nil, fmt.Errorf("failed to list user memberships from repo: %w", err)
	}

	responseMemberships := make([]models.SubscriptionMembershipResponse, 0, len(dbMemberships))
	for _, dbMembership := range dbMemberships {
		hsResponses := s.mapDbSubsToResponseSubs(ctx, []models.HostedSubscription{dbMembership.HostedSubscription})
		if len(hsResponses) == 0 {
			log.Printf("Warning: Failed to map HostedSubscription for membership ID %d", dbMembership.ID)
			continue
		}

		// Get the cost per slot from the mapped HostedSubscriptionResponse
		costPerSlot := hsResponses[0].CostPerSlot

		respMembership := models.SubscriptionMembershipResponse{
			ID:                      dbMembership.ID,
			MemberUserID:            dbMembership.MemberUserID,
			HostedSubscriptionID:    dbMembership.HostedSubscriptionID,
			JoinedDate:              dbMembership.JoinedDate,
			PaymentStatus:           dbMembership.PaymentStatus,
			NextPaymentDate:         dbMembership.NextPaymentDate,
			HostedSubscriptionTitle: dbMembership.HostedSubscription.SubscriptionTitle,
			ServiceProviderName:     dbMembership.HostedSubscription.SubscriptionService.Name,
			ServiceProviderLogoURL:  dbMembership.HostedSubscription.SubscriptionService.LogoURL,
			HostName:                dbMembership.HostedSubscription.User.FullName,
			CostPerSlot:             costPerSlot,
			PaymentQRCodeURL:        dbMembership.HostedSubscription.PaymentQRCodeURL,
		}
		responseMemberships = append(responseMemberships, respMembership)
	}
	return responseMemberships, nil
}

// ListMembersOfSubscription retrieves all members for a specific hosted subscription,
func (s *hostedSubscriptionService) ListMembersOfSubscription(ctx context.Context, authenticatedUserID uint, hostedSubscriptionID uint) ([]models.SubscriptionMembershipResponse, error) {
	hs, err := s.hsRepo.GetByID(ctx, hostedSubscriptionID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSubscriptionNotFound
		}
		return nil, fmt.Errorf("fetching hosted subscription for ownership check: %w", err)
	}
	if hs.HostUserID != authenticatedUserID {
		return nil, ErrForbidden
	}

	dbMemberships, err := s.membershipRepo.ListByHostedSubscriptionID(ctx, hostedSubscriptionID)
	if err != nil {
		return nil, fmt.Errorf("listing members for subscription %d: %w", hostedSubscriptionID, err)
	}

	responseMemberships := make([]models.SubscriptionMembershipResponse, 0, len(dbMemberships))
	for _, dbMembership := range dbMemberships {

		var costPerSlot float64
		if hs.TotalSlots > 0 {
			costPerSlot = hs.CostPerCycle / float64(hs.TotalSlots)
		}

		var memberUserResponse *models.UserResponse
		if dbMembership.User.ID != 0 {
			memberUserResponse = &models.UserResponse{
				ID:                dbMembership.User.ID,
				FullName:          dbMembership.User.FullName,
				ProfilePictureURL: dbMembership.User.ProfilePictureURL,
			}
		}

		respMembership := models.SubscriptionMembershipResponse{
			ID:                      dbMembership.ID,
			MemberUserID:            dbMembership.MemberUserID,
			MemberUser:              memberUserResponse,
			MemberFullName:          dbMembership.User.FullName,
			MemberProfilePictureURL: dbMembership.User.ProfilePictureURL,
			HostedSubscriptionID:    dbMembership.HostedSubscriptionID,
			JoinedDate:              dbMembership.JoinedDate,
			PaymentStatus:           dbMembership.PaymentStatus,
			NextPaymentDate:         dbMembership.NextPaymentDate,
			HostedSubscriptionTitle: hs.SubscriptionTitle,
			ServiceProviderName:     hs.SubscriptionService.Name,
			ServiceProviderLogoURL:  hs.SubscriptionService.LogoURL,
			HostName:                hs.User.FullName,
			CostPerSlot:             costPerSlot,
			PaymentQRCodeURL:        hs.PaymentQRCodeURL,
		}
		responseMemberships = append(responseMemberships, respMembership)
	}

	return responseMemberships, nil
}

// mapDbSubsToResponseSubs helper function
func (s *hostedSubscriptionService) mapDbSubsToResponseSubs(ctx context.Context, dbSubscriptions []models.HostedSubscription) []models.HostedSubscriptionResponse {
	responseSubscriptions := make([]models.HostedSubscriptionResponse, 0, len(dbSubscriptions))
	for _, dbSub := range dbSubscriptions {
		var costPerSlot float64
		if dbSub.TotalSlots > 0 {
			costPerSlot = dbSub.CostPerCycle / float64(dbSub.TotalSlots)
		}
		actualMembersCount := len(dbSub.Memberships)
		availableSlots := max(dbSub.TotalSlots-(actualMembersCount+1), 0)

		var hostUserResponse *models.UserResponse
		if dbSub.User.ID != 0 {
			hostUserResponse = &models.UserResponse{
				ID:                dbSub.User.ID,
				FullName:          dbSub.User.FullName,
				ProfilePictureURL: dbSub.User.ProfilePictureURL,
			}
		} else {
			log.Printf("Warning: Host user (ID: %d) not fully preloaded for HostedSubscription ID %d", dbSub.HostUserID, dbSub.ID)
		}

		memberAvatars := make([]string, 0)
		if hostUserResponse != nil && hostUserResponse.ProfilePictureURL != nil && *hostUserResponse.ProfilePictureURL != "" {
			memberAvatars = append(memberAvatars, *hostUserResponse.ProfilePictureURL)
		}

		for _, membership := range dbSub.Memberships {
			if membership.User.ID != 0 && membership.User.ProfilePictureURL != nil && *membership.User.ProfilePictureURL != "" {
				if len(memberAvatars) < 4 {
					memberAvatars = append(memberAvatars, *membership.User.ProfilePictureURL)
				}
			}
		}

		responseSub := models.HostedSubscriptionResponse{
			ID:                      dbSub.ID,
			Host:                    hostUserResponse,
			SubscriptionTitle:       dbSub.SubscriptionTitle,
			PlanDetails:             dbSub.PlanDetails,
			TotalSlots:              dbSub.TotalSlots,
			CostPerCycle:            dbSub.CostPerCycle,
			BillingCycle:            dbSub.BillingCycle,
			PaymentQRCodeURL:        dbSub.PaymentQRCodeURL,
			Description:             dbSub.Description,
			CreatedAt:               dbSub.CreatedAt,
			UpdatedAt:               dbSub.UpdatedAt,
			SubscriptionServiceName: dbSub.SubscriptionService.Name,
			SubscriptionServiceLogo: dbSub.SubscriptionService.LogoURL,
			MembersCount:            actualMembersCount,
			AvailableSlots:          availableSlots,
			CostPerSlot:             costPerSlot,
			MemberAvatars:           memberAvatars,
		}
		responseSubscriptions = append(responseSubscriptions, responseSub)
	}
	return responseSubscriptions
}
