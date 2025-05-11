package handlers

import (
	"errors"
	"log"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/xNatthapol/hubster/internal/middleware"
	"github.com/xNatthapol/hubster/internal/models"
	"github.com/xNatthapol/hubster/internal/services"
)

// UserHandler handles user profile related requests.
type UserHandler struct {
	userService services.UserService
	validate    *validator.Validate
}

// NewUserHandler creates a new UserHandler.
func NewUserHandler(userService services.UserService) *UserHandler {
	return &UserHandler{
		userService: userService,
		validate:    validator.New(),
	}
}

// GetUserProfile handles requests to fetch the authenticated user's profile.
// @Summary Get current user's profile
// @Description Retrieves profile details of the logged-in user.
// @Tags Users
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.User "User profile details"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 404 {object} ErrorResponse "User not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /user/profile [get]
func (h *UserHandler) GetUserProfile(c *fiber.Ctx) error {
	userID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized: Invalid token context"})
	}

	user, err := h.userService.GetUserProfile(c.Context(), userID)
	if err != nil {
		if errors.Is(err, services.ErrUserNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{Error: err.Error()})
		}
		log.Printf("Error getting user profile for userID %d: %v", userID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve profile"})
	}
	return c.Status(fiber.StatusOK).JSON(user)
}

// UpdateUserProfile handles requests to update the authenticated user's profile.
// @Summary Update current user's profile
// @Description Partially updates profile (full_name, profile_picture_url, phone_number).
// @Tags Users
// @Accept json
// @Produce json
// @Param profile_details body models.UpdateUserRequest true "Profile fields to update"
// @Security BearerAuth
// @Success 200 {object} models.User "Profile updated successfully"
// @Failure 400 {object} ErrorResponse "Validation error or no fields provided"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 404 {object} ErrorResponse "User not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /user/profile [patch]
func (h *UserHandler) UpdateUserProfile(c *fiber.Ctx) error {
	userID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized: Invalid token context"})
	}

	req := new(models.UpdateUserRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Cannot parse JSON"})
	}

	if err := h.validate.Struct(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Validation failed", Details: err.Error()})
	}

	updatedUser, err := h.userService.UpdateUserProfile(c.Context(), userID, req)
	if err != nil {
		if errors.Is(err, services.ErrUserNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{Error: err.Error()})
		}
		if errors.Is(err, services.ErrNoFieldsToUpdate) {
			return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: err.Error()})
		}
		log.Printf("Error updating user profile for userID %d: %v", userID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to update profile"})
	}

	return c.Status(fiber.StatusOK).JSON(updatedUser)
}
