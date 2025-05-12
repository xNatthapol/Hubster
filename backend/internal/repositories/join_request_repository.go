package repositories

import (
	"context"
	"github.com/xNatthapol/hubster/internal/models"
	"gorm.io/gorm"
)

// JoinRequestRepository defines methods for JoinRequest data.
type JoinRequestRepository interface {
	Create(ctx context.Context, jr *models.JoinRequest) error
	FindPendingByRequesterAndSubscription(ctx context.Context, requesterID uint, subscriptionID uint) (*models.JoinRequest, error)
	GetByID(ctx context.Context, id uint) (*models.JoinRequest, error)
	UpdateStatus(ctx context.Context, id uint, status models.JoinRequestStatus) error
	ListBySubscriptionID(ctx context.Context, subscriptionID uint, statusFilter *models.JoinRequestStatus) ([]models.JoinRequest, error)
	ListByRequesterID(ctx context.Context, requesterID uint) ([]models.JoinRequest, error)
}

type joinRequestRepository struct {
	db *gorm.DB
}

// NewJoinRequestRepository creates a new JoinRequestRepository.
func NewJoinRequestRepository(db *gorm.DB) JoinRequestRepository {
	return &joinRequestRepository{db: db}
}

// Create persists a new JoinRequest.
func (r *joinRequestRepository) Create(ctx context.Context, jr *models.JoinRequest) error {
	return r.db.WithContext(ctx).Create(jr).Error
}

// FindPendingByRequesterAndSubscription checks if a user already has a pending request for a subscription.
func (r *joinRequestRepository) FindPendingByRequesterAndSubscription(ctx context.Context, requesterID uint, subscriptionID uint) (*models.JoinRequest, error) {
	var jr models.JoinRequest
	err := r.db.WithContext(ctx).
		Where("requester_user_id = ? AND hosted_subscription_id = ? AND status = ?",
			requesterID, subscriptionID, models.JoinRequestStatusPending).
		First(&jr).Error
	return &jr, err
}

// GetByID retrieves a specific JoinRequest by its ID, preloading the Requester User.
func (r *joinRequestRepository) GetByID(ctx context.Context, id uint) (*models.JoinRequest, error) {
	var jr models.JoinRequest
	err := r.db.WithContext(ctx).Preload("User").First(&jr, id).Error
	return &jr, err
}

// UpdateStatus updates the status of a specific JoinRequest.
func (r *joinRequestRepository) UpdateStatus(ctx context.Context, id uint, status models.JoinRequestStatus) error {
	return r.db.WithContext(ctx).Model(&models.JoinRequest{}).Where("id = ?", id).Update("status", status).Error
}

// ListBySubscriptionID retrieves join requests for a specific hosted subscription
func (r *joinRequestRepository) ListBySubscriptionID(ctx context.Context, subscriptionID uint, statusFilter *models.JoinRequestStatus) ([]models.JoinRequest, error) {
	var requests []models.JoinRequest
	query := r.db.WithContext(ctx).Preload("User").Where("hosted_subscription_id = ?", subscriptionID)

	if statusFilter != nil && *statusFilter != "" {
		query = query.Where("status = ?", *statusFilter)
	}

	err := query.Order("created_at asc").Find(&requests).Error
	return requests, err
}

// ListByRequesterID retrieves all join requests made by a specific user.
func (r *joinRequestRepository) ListByRequesterID(ctx context.Context, requesterID uint) ([]models.JoinRequest, error) {
	var requests []models.JoinRequest
	err := r.db.WithContext(ctx).
		Preload("User").
		Preload("HostedSubscription.SubscriptionService").
		Where("requester_user_id = ?", requesterID).
		Order("created_at desc").
		Find(&requests).Error
	return requests, err
}
