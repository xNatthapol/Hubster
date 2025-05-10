package services

import (
	"context"
	"errors"
	"github.com/xNatthapol/hubster/internal/config"
	"github.com/xNatthapol/hubster/internal/models"
	"github.com/xNatthapol/hubster/internal/repositories"
	"github.com/xNatthapol/hubster/internal/utils"

	"gorm.io/gorm"
)

var (
	ErrUserAlreadyExists  = errors.New("user with this email already exists")
	ErrUserNotFound       = errors.New("user not found")
	ErrInvalidCredentials = errors.New("invalid email or password")
)

type AuthService interface {
	SignUpUser(ctx context.Context, email, password string) (*models.User, error)
	LoginUser(ctx context.Context, email, password string) (string, *models.User, error)
	GetUserByID(ctx context.Context, userID uint) (*models.User, error)
}

type authService struct {
	userRepo repositories.UserRepository
	cfg      *config.Config
}

func NewAuthService(userRepo repositories.UserRepository, cfg *config.Config) AuthService {
	return &authService{userRepo: userRepo, cfg: cfg}
}

func (s *authService) SignUpUser(ctx context.Context, email, password string) (*models.User, error) {
	// Check if user already exists
	_, err := s.userRepo.FindByEmail(ctx, email)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}
	if err == nil {
		return nil, ErrUserAlreadyExists
	}

	// Hash password
	hashedPassword, err := utils.HashPassword(password)
	if err != nil {
		return nil, err
	}

	newUser := &models.User{
		Email:    email,
		Password: hashedPassword,
	}

	err = s.userRepo.CreateUser(ctx, newUser)
	if err != nil {
		return nil, err
	}

	// Return an empty string instead of a password hash in the response object
	newUser.Password = ""
	return newUser, nil
}

func (s *authService) LoginUser(ctx context.Context, email, password string) (string, *models.User, error) {
	// Check if user already exists
	user, err := s.userRepo.FindByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", nil, ErrInvalidCredentials
		}
		return "", nil, err
	}

	// Check password
	if !utils.CheckPasswordHash(password, user.Password) {
		return "", nil, ErrInvalidCredentials
	}

	// Generate JWT token
	token, err := utils.GenerateJWT(user.ID, s.cfg)
	if err != nil {
		return "", nil, err
	}

	// Return an empty string instead of a password hash in the response object
	user.Password = ""
	return token, user, nil
}

// GetUserByID retrieves a user by their ID.
func (s *authService) GetUserByID(ctx context.Context, userID uint) (*models.User, error) {
	user, err := s.userRepo.FindByID(ctx, userID)

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}

	// Return an empty string instead of a password hash in the response object
	user.Password = ""
	return user, nil
}
