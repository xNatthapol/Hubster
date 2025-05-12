package repositories

import (
	"context"
	"github.com/xNatthapol/hubster/internal/models"
	"gorm.io/gorm"
	"time"
)

// PaymentRecordRepository defines methods for interacting with PaymentRecord data.
type PaymentRecordRepository interface {
	Create(ctx context.Context, pr *models.PaymentRecord) error
	GetByID(ctx context.Context, id uint) (*models.PaymentRecord, error)
	UpdateStatus(ctx context.Context, id uint, status models.PaymentRecordStatus, reviewedByUserID *uint) error
	ListBySubscriptionMembershipID(ctx context.Context, membershipID uint) ([]models.PaymentRecord, error)
	ListByHostedSubscriptionIDAndStatus(ctx context.Context, hostedSubscriptionID uint, status models.PaymentRecordStatus) ([]models.PaymentRecord, error)
}

type paymentRecordRepository struct {
	db *gorm.DB
}

// NewPaymentRecordRepository creates a new PaymentRecordRepository.
func NewPaymentRecordRepository(db *gorm.DB) PaymentRecordRepository {
	return &paymentRecordRepository{db: db}
}

// Create persists a new PaymentRecord.
func (r *paymentRecordRepository) Create(ctx context.Context, pr *models.PaymentRecord) error {
	return r.db.WithContext(ctx).Create(pr).Error
}

// GetByID retrieves a specific PaymentRecord by its ID.
func (r *paymentRecordRepository) GetByID(ctx context.Context, id uint) (*models.PaymentRecord, error) {
	var pr models.PaymentRecord
	err := r.db.WithContext(ctx).
		Preload("SubscriptionMembership.User").
		Preload("SubscriptionMembership.HostedSubscription.User").
		Preload("SubscriptionMembership.HostedSubscription.SubscriptionService").
		First(&pr, id).Error
	return &pr, err
}

// UpdateStatus updates the status, reviewer, and notes of a specific PaymentRecord.
func (r *paymentRecordRepository) UpdateStatus(ctx context.Context, id uint, status models.PaymentRecordStatus, reviewedByUserID *uint) error {
	updates := map[string]any{
		"status":      status,
		"reviewed_at": time.Now().UTC(),
	}
	if reviewedByUserID != nil {
		updates["reviewed_by_user_id"] = reviewedByUserID
	}
	return r.db.WithContext(ctx).Model(&models.PaymentRecord{}).Where("id = ?", id).Updates(updates).Error
}

// ListBySubscriptionMembershipID retrieves all payment records for a specific membership, ordered by creation.
func (r *paymentRecordRepository) ListBySubscriptionMembershipID(ctx context.Context, membershipID uint) ([]models.PaymentRecord, error) {
	var records []models.PaymentRecord
	err := r.db.WithContext(ctx).
		Where("subscription_membership_id = ?", membershipID).
		Order("created_at desc").
		Find(&records).Error
	return records, err
}

// ListByHostedSubscriptionIDAndStatus retrieves payment records for a hosted subscription filtered by status.
func (r *paymentRecordRepository) ListByHostedSubscriptionIDAndStatus(ctx context.Context, hostedSubscriptionID uint, status models.PaymentRecordStatus) ([]models.PaymentRecord, error) {
	var records []models.PaymentRecord
	err := r.db.WithContext(ctx).
		Joins("JOIN subscription_memberships sm ON sm.id = payment_records.subscription_membership_id").
		Where("sm.hosted_subscription_id = ? AND payment_records.status = ?", hostedSubscriptionID, status).
		Preload("SubscriptionMembership.User").
		Order("payment_records.created_at asc").
		Find(&records).Error
	return records, err
}
