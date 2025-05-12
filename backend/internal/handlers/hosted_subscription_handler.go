package handlers

import (
	"errors"
	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/xNatthapol/hubster/internal/middleware"
	"github.com/xNatthapol/hubster/internal/models"
	"github.com/xNatthapol/hubster/internal/services"
	"log"
	"strconv"
)

// HostedSubscriptionHandler handles requests related to hosted subscriptions.
type HostedSubscriptionHandler struct {
	service  services.HostedSubscriptionService
	validate *validator.Validate
}

// NewHostedSubscriptionHandler creates a new HostedSubscriptionHandler.
func NewHostedSubscriptionHandler(service services.HostedSubscriptionService) *HostedSubscriptionHandler {
	return &HostedSubscriptionHandler{
		service:  service,
		validate: validator.New(),
	}
}

// CreateHostedSubscription handles requests to create a new hosted subscription.
// @Summary Create a new hosted subscription
// @Description Allows an authenticated user to create/offer a new subscription for sharing.
// @Tags HostedSubscriptions
// @Accept json
// @Produce json
// @Param subscription_details body models.CreateHostedSubscriptionRequest true "Details of the subscription to host"
// @Security BearerAuth
// @Success 201 {object} models.HostedSubscriptionResponse "Hosted subscription created successfully with enriched details"
// @Failure 400 {object} ErrorResponse "Validation error or invalid input"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /hosted-subscriptions [post]
func (h *HostedSubscriptionHandler) CreateHostedSubscription(c *fiber.Ctx) error {
	hostUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized: Invalid user context"})
	}
	req := new(models.CreateHostedSubscriptionRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Cannot parse JSON request body"})
	}
	if err := h.validate.Struct(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Validation failed", Details: err.Error()})
	}
	hsResponse, err := h.service.CreateHostedSubscription(c.Context(), hostUserID, req)
	if err != nil {
		if errors.Is(err, services.ErrServiceNotFound) {
			return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: err.Error(), Details: "Invalid subscription_service_id provided."})
		}
		log.Printf("Error creating hosted subscription for user %d: %v", hostUserID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to create hosted subscription"})
	}
	return c.Status(fiber.StatusCreated).JSON(hsResponse)
}

// ListUserHostedSubscriptions handles requests for the current user's hosted subscriptions.
// @Summary List user's hosted subscriptions
// @Description Retrieves all subscriptions hosted by the currently authenticated user.
// @Tags HostedSubscriptions
// @Produce json
// @Security BearerAuth
// @Success 200 {array} models.HostedSubscriptionResponse "A list of hosted subscriptions"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /users/me/hosted-subscriptions [get]
func (h *HostedSubscriptionHandler) ListUserHostedSubscriptions(c *fiber.Ctx) error {
	hostUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized: Invalid user context"})
	}

	subscriptions, err := h.service.ListHostedSubscriptionsByUserID(c.Context(), hostUserID)
	if err != nil {
		log.Printf("Error listing hosted subscriptions for user %d: %v", hostUserID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve hosted subscriptions"})
	}

	// If no subscriptions are found, return an empty list, not an error.
	if subscriptions == nil {
		subscriptions = []models.HostedSubscriptionResponse{}
	}

	return c.Status(fiber.StatusOK).JSON(subscriptions)
}

// ExploreAllHostedSubscriptions handles requests to list all publicly available hosted subscriptions.
// @Summary Explore all available hosted subscriptions
// @Description Retrieves a list of all hosted subscriptions. Supports search, service filtering, and sorting.
// @Tags HostedSubscriptions
// @Produce json
// @Param search query string false "Search term for subscription title, plan, or description"
// @Param subscription_service_id query int false "Filter by Subscription Service ID"
// @Param sort_by query string false "Sort order (e.g., cost_asc, cost_desc, created_at_desc, name_asc)" Enums(cost_asc,cost_desc,created_at_desc,name_asc,name_desc)
// @Security BearerAuth
// @Success 200 {array} models.HostedSubscriptionResponse "A list of available hosted subscriptions"
// @Failure 400 {object} ErrorResponse "Invalid query parameters"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /hosted-subscriptions [get]
func (h *HostedSubscriptionHandler) ExploreAllHostedSubscriptions(c *fiber.Ctx) error {
	filters := &models.ExploreSubscriptionFilters{}

	if searchTerm := c.Query("search"); searchTerm != "" {
		filters.SearchTerm = &searchTerm
	}

	if serviceIDStr := c.Query("subscription_service_id"); serviceIDStr != "" {
		serviceID, err := strconv.ParseUint(serviceIDStr, 10, 32)
		if err == nil && serviceID > 0 {
			id := uint(serviceID)
			filters.SubscriptionServiceID = &id
		} else {
			log.Printf("Warning: Invalid subscription_service_id query param: %s", serviceIDStr)
		}
	}

	sortBy := c.Query("sort_by", "created_at_desc")

	subscriptions, err := h.service.ExploreAllHostedSubscriptions(c.Context(), filters, sortBy)
	if err != nil {
		log.Printf("Error exploring hosted subscriptions: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve subscriptions"})
	}

	if subscriptions == nil {
		subscriptions = []models.HostedSubscriptionResponse{}
	}
	return c.Status(fiber.StatusOK).JSON(subscriptions)
}

// GetHostedSubscriptionDetails handles requests for a specific hosted subscription.
// @Summary Get details of a specific hosted subscription
// @Description Retrieves details of a specific hosted subscription by its ID.
// @Tags HostedSubscriptions
// @Produce json
// @Param id path int true "Hosted Subscription ID"
// @Security BearerAuth
// @Success 200 {object} models.HostedSubscriptionResponse "Details of the hosted subscription"
// @Failure 400 {object} ErrorResponse "Invalid ID format"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden (user may not have access)"
// @Failure 404 {object} ErrorResponse "Subscription not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /hosted-subscriptions/{id} [get]
func (h *HostedSubscriptionHandler) GetHostedSubscriptionDetails(c *fiber.Ctx) error {
	authenticatedUserID, _ := c.Locals(middleware.UserIDKey).(uint)
	idStr := c.Params("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid subscription ID format"})
	}
	subscription, err := h.service.GetHostedSubscriptionDetailsByID(c.Context(), uint(id), authenticatedUserID)
	if err != nil {
		log.Printf("Error getting subscription details for ID %d: %v", id, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve subscription details"})
	}
	return c.Status(fiber.StatusOK).JSON(subscription)
}

// CreateJoinRequest handles a user's request to join a hosted subscription.
// @Summary Request to join a subscription
// @Description Allows an authenticated user to send a request to join a specific hosted subscription. (No request body needed)
// @Tags HostedSubscriptions
// @Produce json
// @Param id path int true "Hosted Subscription ID to join"
// @Security BearerAuth
// @Success 201 {object} models.JoinRequest "Join request created successfully"
// @Failure 400 {object} ErrorResponse "Invalid input or request (e.g., subscription full, already member)"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden (e.g., host trying to join own subscription)"
// @Failure 404 {object} ErrorResponse "Hosted subscription not found"
// @Failure 409 {object} ErrorResponse "Conflict (e.g., already sent a pending request)"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /hosted-subscriptions/{id}/join-requests [post]
func (h *HostedSubscriptionHandler) CreateJoinRequest(c *fiber.Ctx) error {
	requesterUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized: Invalid user context"})
	}

	subscriptionIDStr := c.Params("id") // ID of the HostedSubscription
	hostedSubscriptionID, err := strconv.ParseUint(subscriptionIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid hosted subscription ID format"})
	}

	joinRequest, err := h.service.CreateJoinRequest(c.Context(), requesterUserID, uint(hostedSubscriptionID))
	if err != nil {
		switch {
		case errors.Is(err, services.ErrSubscriptionNotFound):
			return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{Error: err.Error()})
		case errors.Is(err, services.ErrSubscriptionFull),
			errors.Is(err, services.ErrHostCannotJoinOwn):
			return c.Status(fiber.StatusForbidden).JSON(ErrorResponse{Error: err.Error()})
		case errors.Is(err, services.ErrAlreadyMember),
			errors.Is(err, services.ErrAlreadyRequestedToJoin):
			return c.Status(fiber.StatusConflict).JSON(ErrorResponse{Error: err.Error()})
		default:
			log.Printf("Error creating join request for user %d, subscription %d: %v", requesterUserID, hostedSubscriptionID, err)
			return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to create join request"})
		}
	}

	return c.Status(fiber.StatusCreated).JSON(joinRequest)
}

// ListJoinRequestsForSubscription handles hosts viewing join requests for their subscription.
// @Summary List join requests for a specific hosted subscription
// @Description Retrieves join requests for a subscription owned by the authenticated host. Can filter by status.
// @Tags JoinRequests
// @Produce json
// @Param subscriptionId path int true "ID of the Hosted Subscription"
// @Param status query string false "Filter by request status (e.g., Pending, Approved, Declined)" Enums(Pending,Approved,Declined,Cancelled)
// @Security BearerAuth
// @Success 200 {array} models.JoinRequest "A list of join requests"
// @Failure 400 {object} ErrorResponse "Invalid subscription ID format"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden (not the host of this subscription)"
// @Failure 404 {object} ErrorResponse "Subscription not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /hosted-subscriptions/{subscriptionId}/join-requests [get]
func (h *HostedSubscriptionHandler) ListJoinRequestsForSubscription(c *fiber.Ctx) error {
	hostUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized: Invalid user context"})
	}

	subscriptionIDStr := c.Params("subscriptionId")
	subscriptionID, err := strconv.ParseUint(subscriptionIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid subscription ID format"})
	}

	statusQuery := c.Query("status")
	var statusFilter *models.JoinRequestStatus
	if statusQuery != "" {
		s := models.JoinRequestStatus(statusQuery)
		if s == models.JoinRequestStatusPending || s == models.JoinRequestStatusApproved || s == models.JoinRequestStatusDeclined || s == models.JoinRequestStatusCancelled {
			statusFilter = &s
		} else {
			return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid status filter value"})
		}
	}

	requests, err := h.service.ListJoinRequestsForHost(c.Context(), hostUserID, uint(subscriptionID), statusFilter)
	if err != nil {
		if errors.Is(err, services.ErrSubscriptionNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{Error: err.Error()})
		}
		if errors.Is(err, services.ErrForbidden) {
			return c.Status(fiber.StatusForbidden).JSON(ErrorResponse{Error: err.Error()})
		}
		log.Printf("Error listing join requests for host %d, sub %d: %v", hostUserID, subscriptionID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve join requests"})
	}
	if requests == nil {
		requests = []models.JoinRequest{}
	}
	return c.Status(fiber.StatusOK).JSON(requests)
}

// ApproveJoinRequest handles a host approving a join request.
// @Summary Approve a join request
// @Description Allows the host of a subscription to approve a pending join request.
// @Tags JoinRequests
// @Produce json
// @Param requestId path int true "ID of the Join Request to approve"
// @Security BearerAuth
// @Success 200 {object} models.SubscriptionMembership "Membership created upon approval"
// @Failure 400 {object} ErrorResponse "Invalid request ID or request not pending"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden (not host, or subscription full)"
// @Failure 404 {object} ErrorResponse "Join request or subscription not found"
// @Failure 409 {object} ErrorResponse "Conflict (e.g., user already a member)"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /join-requests/{requestId}/approve [patch]
func (h *HostedSubscriptionHandler) ApproveJoinRequest(c *fiber.Ctx) error {
	hostUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized"})
	}

	requestIDStr := c.Params("requestId")
	requestID, err := strconv.ParseUint(requestIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid request ID format"})
	}

	membership, err := h.service.ApproveJoinRequest(c.Context(), hostUserID, uint(requestID))
	if err != nil {
		switch {
		case errors.Is(err, services.ErrJoinRequestNotFound), errors.Is(err, services.ErrSubscriptionNotFound):
			return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{Error: err.Error()})
		case errors.Is(err, services.ErrCannotManageRequest), errors.Is(err, services.ErrSubscriptionFull):
			return c.Status(fiber.StatusForbidden).JSON(ErrorResponse{Error: err.Error()})
		case errors.Is(err, services.ErrJoinRequestNotPending):
			return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: err.Error()})
		case errors.Is(err, services.ErrAlreadyMember):
			return c.Status(fiber.StatusConflict).JSON(ErrorResponse{Error: err.Error()})
		default:
			log.Printf("Error approving join request %d by host %d: %v", requestID, hostUserID, err)
			return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to approve join request"})
		}
	}
	return c.Status(fiber.StatusOK).JSON(membership)
}

// DeclineJoinRequest handles a host declining a join request.
// @Summary Decline a join request
// @Description Allows the host of a subscription to decline a pending join request.
// @Tags JoinRequests
// @Produce json
// @Param requestId path int true "ID of the Join Request to decline"
// @Security BearerAuth
// @Success 200 {object} object "message: Join request declined successfully"
// @Failure 400 {object} ErrorResponse "Invalid request ID or request not pending"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden (not the host)"
// @Failure 404 {object} ErrorResponse "Join request or subscription not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /join-requests/{requestId}/decline [patch]
func (h *HostedSubscriptionHandler) DeclineJoinRequest(c *fiber.Ctx) error {
	hostUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized"})
	}

	requestIDStr := c.Params("requestId")
	requestID, err := strconv.ParseUint(requestIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid request ID format"})
	}

	err = h.service.DeclineJoinRequest(c.Context(), hostUserID, uint(requestID))
	if err != nil {
		switch {
		case errors.Is(err, services.ErrJoinRequestNotFound), errors.Is(err, services.ErrSubscriptionNotFound):
			return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{Error: err.Error()})
		case errors.Is(err, services.ErrCannotManageRequest):
			return c.Status(fiber.StatusForbidden).JSON(ErrorResponse{Error: err.Error()})
		case errors.Is(err, services.ErrJoinRequestNotPending):
			return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: err.Error()})
		default:
			log.Printf("Error declining join request %d by host %d: %v", requestID, hostUserID, err)
			return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to decline join request"})
		}
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "Join request declined successfully"})
}

// ListSubscriptionMembers handles a host viewing members of their specific subscription.
// @Summary List members of a hosted subscription
// @Description Retrieves a list of all members for a specific subscription owned by the authenticated host.
// @Tags HostedSubscriptions
// @Produce json
// @Param subscriptionId path int true "ID of the Hosted Subscription"
// @Security BearerAuth
// @Success 200 {array} models.SubscriptionMembershipResponse "A list of members and their status"
// @Failure 400 {object} ErrorResponse "Invalid subscription ID format"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden (not the host of this subscription)"
// @Failure 404 {object} ErrorResponse "Subscription not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /hosted-subscriptions/{subscriptionId}/members [get]
func (h *HostedSubscriptionHandler) ListSubscriptionMembers(c *fiber.Ctx) error {
	authenticatedUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized: Invalid user context"})
	}

	subscriptionIDStr := c.Params("subscriptionId")
	subscriptionID, err := strconv.ParseUint(subscriptionIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid subscription ID format"})
	}

	memberships, err := h.service.ListMembersOfSubscription(c.Context(), authenticatedUserID, uint(subscriptionID))
	if err != nil {
		if errors.Is(err, services.ErrSubscriptionNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{Error: err.Error()})
		}
		if errors.Is(err, services.ErrForbidden) {
			return c.Status(fiber.StatusForbidden).JSON(ErrorResponse{Error: err.Error()})
		}
		log.Printf("Error listing members for subscription %d by host %d: %v", subscriptionID, authenticatedUserID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve subscription members"})
	}

	if memberships == nil {
		memberships = []models.SubscriptionMembershipResponse{}
	}
	return c.Status(fiber.StatusOK).JSON(memberships)
}
