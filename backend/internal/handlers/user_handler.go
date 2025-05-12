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
	userService      services.UserService
	hostedSubService services.HostedSubscriptionService
	validate         *validator.Validate
}

// NewUserHandler creates a new UserHandler.
func NewUserHandler(userService services.UserService, hostedSubService services.HostedSubscriptionService) *UserHandler {
	return &UserHandler{
		userService:      userService,
		hostedSubService: hostedSubService,
		validate:         validator.New(),
	}
}

// UpdateCurrentUserProfile handles requests to update the authenticated user's profile.
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
// @Router /users/me/profile [patch]
func (h *UserHandler) UpdateCurrentUserProfile(c *fiber.Ctx) error {
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

// ListMyJoinRequests handles listing join requests made by the current user.
// @Summary List my sent join requests
// @Description Retrieves all join requests sent by the currently authenticated user.
// @Tags MyJoinRequests
// @Produce json
// @Security BearerAuth
// @Success 200 {array} models.JoinRequest "A list of the user's join requests"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /users/me/join-requests [get]
func (h *UserHandler) ListMyJoinRequests(c *fiber.Ctx) error {
	requesterUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized"})
	}

	requests, err := h.hostedSubService.ListMyJoinRequests(c.Context(), requesterUserID)
	if err != nil {
		log.Printf("Error listing user's join requests for user %d: %v", requesterUserID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve your join requests"})
	}
	if requests == nil {
		requests = []models.JoinRequest{}
	}
	return c.Status(fiber.StatusOK).JSON(requests)
}

// ListMyMemberships handles listing subscriptions the current user is a member of.
// @Summary List my subscription memberships
// @Description Retrieves all subscriptions the currently authenticated user has joined.
// @Tags MyMemberships
// @Produce json
// @Security BearerAuth
// @Success 200 {array} models.SubscriptionMembershipResponse "A list of the user's memberships"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /users/me/memberships [get]
func (h *UserHandler) ListMyMemberships(c *fiber.Ctx) error {
	memberUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized"})
	}

	memberships, err := h.hostedSubService.ListMyMemberships(c.Context(), memberUserID)
	if err != nil {
		log.Printf("Error listing user's memberships for user %d: %v", memberUserID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve your memberships"})
	}
	if memberships == nil {
		memberships = []models.SubscriptionMembershipResponse{}
	}
	return c.Status(fiber.StatusOK).JSON(memberships)
}
