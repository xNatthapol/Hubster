package services

import (
	"context"
	"errors"
	"github.com/xNatthapol/hubster/internal/models"
	"github.com/xNatthapol/hubster/internal/repositories"
	"gorm.io/gorm"
)

// UserService defines the interface for user profile operations.
type UserService interface {
	GetUserProfile(ctx context.Context, userID uint) (*models.User, error)
	UpdateUserProfile(ctx context.Context, userID uint, req *models.UpdateUserRequest) (*models.User, error)
}

type userService struct {
	userRepo repositories.UserRepository
}

// NewUserService creates a new UserService instance.
func NewUserService(userRepo repositories.UserRepository) UserService {
	return &userService{userRepo: userRepo}
}

// GetUserProfile retrieves a user's profile by their ID.
func (s *userService) GetUserProfile(ctx context.Context, userID uint) (*models.User, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	user.Password = ""
	return user, nil
}

// UpdateUserProfile updates the profile information for the given userID.
func (s *userService) UpdateUserProfile(ctx context.Context, userID uint, req *models.UpdateUserRequest) (*models.User, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}

	updated := false
	if req.FullName != nil {
		user.FullName = *req.FullName
		updated = true
	}
	if req.ProfilePictureURL != nil {
		user.ProfilePictureURL = req.ProfilePictureURL
		updated = true
	}
	if req.PhoneNumber != nil {
		user.PhoneNumber = req.PhoneNumber
		updated = true
	}

	if !updated {
		return user, ErrNoFieldsToUpdate
	}

	if err := s.userRepo.UpdateUser(ctx, user); err != nil {
		return nil, err
	}

	user.Password = ""
	return user, nil
}
