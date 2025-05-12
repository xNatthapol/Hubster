package repositories

import (
	"context"
	"github.com/xNatthapol/hubster/internal/models"
	"gorm.io/gorm"
	"strings"
)

// HostedSubscriptionRepository defines methods for HostedSubscription data.
type HostedSubscriptionRepository interface {
	Create(ctx context.Context, hs *models.HostedSubscription) error
	ListByHostID(ctx context.Context, hostID uint) ([]models.HostedSubscription, error)
	ListFiltered(ctx context.Context, filters *models.ExploreSubscriptionFilters, sortBy string) ([]models.HostedSubscription, error)
	GetByID(ctx context.Context, id uint) (*models.HostedSubscription, error)
}

type hostedSubscriptionRepository struct {
	db *gorm.DB
}

// NewHostedSubscriptionRepository creates a new HostedSubscriptionRepository.
func NewHostedSubscriptionRepository(db *gorm.DB) HostedSubscriptionRepository {
	return &hostedSubscriptionRepository{db: db}
}

// Create persists a new HostedSubscription.
func (r *hostedSubscriptionRepository) Create(ctx context.Context, hs *models.HostedSubscription) error {
	return r.db.WithContext(ctx).Create(hs).Error
}

// ListByHostID retrieves all hosted subscriptions for a given host ID.
func (r *hostedSubscriptionRepository) ListByHostID(ctx context.Context, hostID uint) ([]models.HostedSubscription, error) {
	var subscriptions []models.HostedSubscription
	err := r.db.WithContext(ctx).
		Preload("SubscriptionService").
		Preload("Memberships.User").
		Preload("User").
		Where("host_user_id = ?", hostID).
		Order("created_at desc").
		Find(&subscriptions).Error
	return subscriptions, err
}

// ListFiltered retrieves a filtered and sorted list of hosted subscriptions.
func (r *hostedSubscriptionRepository) ListFiltered(ctx context.Context, filters *models.ExploreSubscriptionFilters, sortBy string) ([]models.HostedSubscription, error) {
	var subscriptions []models.HostedSubscription
	query := r.db.WithContext(ctx).Model(&models.HostedSubscription{})

	// Apply filters
	if filters != nil {
		if filters.SearchTerm != nil && *filters.SearchTerm != "" {
			searchTerm := "%" + strings.ToLower(strings.TrimSpace(*filters.SearchTerm)) + "%"
			query = query.Where(
				r.db.Where("LOWER(subscription_title) LIKE ?", searchTerm).
					Or("LOWER(plan_details) LIKE ?", searchTerm).
					Or("LOWER(description) LIKE ?", searchTerm),
			)
		}
		if filters.SubscriptionServiceID != nil && *filters.SubscriptionServiceID > 0 {
			query = query.Where("subscription_service_id = ?", *filters.SubscriptionServiceID)
		}
	}

	// Apply ordering
	orderClause := "created_at desc"
	if sortBy != "" {
		switch strings.ToLower(sortBy) {
		case "cost_asc":
			orderClause = "cost_per_cycle asc, created_at desc"
		case "cost_desc":
			orderClause = "cost_per_cycle desc, created_at desc"
		case "name_asc":
			orderClause = "subscription_title asc, created_at desc"
		case "name_desc":
			orderClause = "subscription_title desc, created_at desc"
		}
	}
	query = query.Order(orderClause)

	err := query.Preload("SubscriptionService").
		Preload("Memberships.User").
		Preload("User").
		Find(&subscriptions).Error

	return subscriptions, err
}

// GetByID retrieves a specific hosted subscription by its ID.
func (r *hostedSubscriptionRepository) GetByID(ctx context.Context, id uint) (*models.HostedSubscription, error) {
	var hs models.HostedSubscription
	err := r.db.WithContext(ctx).
		Preload("SubscriptionService").
		Preload("Memberships.User").
		Preload("User").
		First(&hs, id).Error
	return &hs, err
}
