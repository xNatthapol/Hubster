package services

import (
	"context"
	"errors"
	"fmt"
	"github.com/xNatthapol/hubster/internal/models"
	"github.com/xNatthapol/hubster/internal/repositories"
	"gorm.io/gorm"
)

// ErrServiceAlreadyExists is returned when trying to create a service that already exists.
var ErrServiceAlreadyExists = errors.New("subscription service with this name already exists")

// SubscriptionCatalogService defines the interface for managing predefined subscription services.
type SubscriptionCatalogService interface {
	CreateSubscriptionService(ctx context.Context, req *models.CreateSubscriptionServiceRequest) (*models.SubscriptionService, error)
	ListSubscriptionServices(ctx context.Context) ([]models.SubscriptionService, error)
}

type subscriptionCatalogService struct {
	repo repositories.SubscriptionServiceRepository
}

// NewSubscriptionCatalogService creates a new SubscriptionCatalogService instance.
func NewSubscriptionCatalogService(repo repositories.SubscriptionServiceRepository) SubscriptionCatalogService {
	return &subscriptionCatalogService{repo: repo}
}

// CreateSubscriptionService creates a new predefined subscription service.
func (s *subscriptionCatalogService) CreateSubscriptionService(ctx context.Context, req *models.CreateSubscriptionServiceRequest) (*models.SubscriptionService, error) {
	_, err := s.repo.FindSubscriptionServiceByName(ctx, req.Name)
	if err == nil {
		return nil, ErrServiceAlreadyExists
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("checking for existing service: %w", err)
	}

	service := &models.SubscriptionService{
		Name:    req.Name,
		LogoURL: req.LogoURL,
	}

	if err := s.repo.CreateSubscriptionService(ctx, service); err != nil {
		return nil, fmt.Errorf("creating subscription service: %w", err)
	}
	return service, nil
}

// ListSubscriptionServices returns a list of all predefined subscription services.
func (s *subscriptionCatalogService) ListSubscriptionServices(ctx context.Context) ([]models.SubscriptionService, error) {
	return s.repo.ListSubscriptionServices(ctx)
}
