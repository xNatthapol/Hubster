package repositories

import (
	"context"
	"github.com/xNatthapol/hubster/internal/models"
	"gorm.io/gorm"
)

// SubscriptionServiceRepository defines methods for interacting with subscription service data.
type SubscriptionServiceRepository interface {
	CreateSubscriptionService(ctx context.Context, service *models.SubscriptionService) error
	GetByID(ctx context.Context, id uint) (*models.SubscriptionService, error)
	FindSubscriptionServiceByName(ctx context.Context, name string) (*models.SubscriptionService, error)
	ListSubscriptionServices(ctx context.Context) ([]models.SubscriptionService, error)
}

type subscriptionServiceRepository struct {
	db *gorm.DB
}

// NewSubscriptionServiceRepository creates a new SubscriptionServiceRepository.
func NewSubscriptionServiceRepository(db *gorm.DB) SubscriptionServiceRepository {
	return &subscriptionServiceRepository{db: db}
}

// CreateSubscriptionService creates a new subscription service record.
func (r *subscriptionServiceRepository) CreateSubscriptionService(ctx context.Context, service *models.SubscriptionService) error {
	return r.db.WithContext(ctx).Create(service).Error
}

func (r *subscriptionServiceRepository) GetByID(ctx context.Context, id uint) (*models.SubscriptionService, error) {
	var service models.SubscriptionService
	err := r.db.WithContext(ctx).First(&service, id).Error
	return &service, err
}

// FindSubscriptionServiceByName finds a subscription service by its name.
func (r *subscriptionServiceRepository) FindSubscriptionServiceByName(ctx context.Context, name string) (*models.SubscriptionService, error) {
	var service models.SubscriptionService
	err := r.db.WithContext(ctx).Where("name = ?", name).First(&service).Error
	return &service, err
}

// ListSubscriptionServices retrieves all subscription services.
func (r *subscriptionServiceRepository) ListSubscriptionServices(ctx context.Context) ([]models.SubscriptionService, error) {
	var services []models.SubscriptionService
	err := r.db.WithContext(ctx).Order("name asc").Find(&services).Error
	return services, err
}
