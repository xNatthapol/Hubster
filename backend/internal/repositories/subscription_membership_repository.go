package repositories

import (
	"context"
	"github.com/xNatthapol/hubster/internal/models"
	"gorm.io/gorm"
	"time"
)

// SubscriptionMembershipRepository defines methods for SubscriptionMembership data.
type SubscriptionMembershipRepository interface {
	Create(ctx context.Context, sm *models.SubscriptionMembership) error
	FindByUserAndSubscription(ctx context.Context, userID uint, hostedSubscriptionID uint) (*models.SubscriptionMembership, error)
	ListByUserID(ctx context.Context, userID uint) ([]models.SubscriptionMembership, error)
	ListByHostedSubscriptionID(ctx context.Context, hostedSubscriptionID uint) ([]models.SubscriptionMembership, error)
	GetByID(ctx context.Context, id uint) (*models.SubscriptionMembership, error)
	UpdatePaymentStatus(ctx context.Context, id uint, status models.PaymentStatusType) error
	UpdatePaymentAndNextDueDate(ctx context.Context, id uint, status models.PaymentStatusType, nextDueDate *time.Time) error
}

type subscriptionMembershipRepository struct {
	db *gorm.DB
}

// NewSubscriptionMembershipRepository creates a new SubscriptionMembershipRepository.
func NewSubscriptionMembershipRepository(db *gorm.DB) SubscriptionMembershipRepository {
	return &subscriptionMembershipRepository{db: db}
}

// Create persists a new SubscriptionMembership.
func (r *subscriptionMembershipRepository) Create(ctx context.Context, sm *models.SubscriptionMembership) error {
	return r.db.WithContext(ctx).Create(sm).Error
}

// FindByUserAndSubscription finds an active membership for a user in a specific subscription.
func (r *subscriptionMembershipRepository) FindByUserAndSubscription(ctx context.Context, userID uint, hostedSubscriptionID uint) (*models.SubscriptionMembership, error) {
	var sm models.SubscriptionMembership
	err := r.db.WithContext(ctx).
		Where("member_user_id = ? AND hosted_subscription_id = ?", userID, hostedSubscriptionID).
		First(&sm).Error
	return &sm, err
}

// ListByUserID retrieves all memberships for a user, preloading HostedSubscription and its Service.
func (r *subscriptionMembershipRepository) ListByUserID(ctx context.Context, userID uint) ([]models.SubscriptionMembership, error) {
	var memberships []models.SubscriptionMembership
	err := r.db.WithContext(ctx).
		Where("member_user_id = ?", userID).
		Preload("HostedSubscription.SubscriptionService").
		Preload("HostedSubscription.User").
		Order("created_at desc").
		Find(&memberships).Error
	return memberships, err
}

// ListByHostedSubscriptionID retrieves all memberships for a hosted subscription, preloading member (User) details.
func (r *subscriptionMembershipRepository) ListByHostedSubscriptionID(ctx context.Context, hostedSubscriptionID uint) ([]models.SubscriptionMembership, error) {
	var memberships []models.SubscriptionMembership
	err := r.db.WithContext(ctx).
		Where("hosted_subscription_id = ?", hostedSubscriptionID).
		Preload("User").
		Order("created_at asc").
		Find(&memberships).Error
	return memberships, err
}

func (r *subscriptionMembershipRepository) GetByID(ctx context.Context, id uint) (*models.SubscriptionMembership, error) {
	var sm models.SubscriptionMembership
	err := r.db.WithContext(ctx).
		Preload("HostedSubscription").
		First(&sm, id).Error
	return &sm, err
}

func (r *subscriptionMembershipRepository) UpdatePaymentStatus(ctx context.Context, id uint, status models.PaymentStatusType) error {
	return r.db.WithContext(ctx).Model(&models.SubscriptionMembership{}).Where("id = ?", id).Update("payment_status", status).Error
}

func (r *subscriptionMembershipRepository) UpdatePaymentAndNextDueDate(ctx context.Context, id uint, status models.PaymentStatusType, nextDueDate *time.Time) error {
	updates := map[string]any{
		"payment_status": status,
	}
	if nextDueDate != nil {
		updates["next_payment_date"] = nextDueDate
	} else {
		updates["next_payment_date"] = gorm.Expr("NULL")
	}
	return r.db.WithContext(ctx).Model(&models.SubscriptionMembership{}).Where("id = ?", id).Updates(updates).Error
}
