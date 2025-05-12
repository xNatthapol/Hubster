package handlers

import (
	"errors"
	"log"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/xNatthapol/hubster/internal/models"
	"github.com/xNatthapol/hubster/internal/services"
)

// SubscriptionServiceHandler handles requests related to predefined subscription services.
type SubscriptionServiceHandler struct {
	catalogService services.SubscriptionCatalogService
	validate       *validator.Validate
}

// NewSubscriptionServiceHandler creates a new SubscriptionServiceHandler.
func NewSubscriptionServiceHandler(catalogService services.SubscriptionCatalogService) *SubscriptionServiceHandler {
	return &SubscriptionServiceHandler{
		catalogService: catalogService,
		validate:       validator.New(),
	}
}

// CreateSubscriptionService handles requests to create a new predefined subscription service.
// @Summary Create a new subscription service
// @Description Adds a new service (e.g., Netflix, Spotify) to the list of available services. (Admin/Protected)
// @Tags SubscriptionServices
// @Accept json
// @Produce json
// @Param service_details body models.CreateSubscriptionServiceRequest true "Details of the service to create"
// @Security BearerAuth
// @Success 201 {object} models.SubscriptionService "Subscription service created successfully"
// @Failure 400 {object} ErrorResponse "Validation error"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 409 {object} ErrorResponse "Service with this name already exists"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /subscription-services/add [post]
func (h *SubscriptionServiceHandler) CreateSubscriptionService(c *fiber.Ctx) error {
	req := new(models.CreateSubscriptionServiceRequest)

	if err := c.BodyParser(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Cannot parse JSON"})
	}
	if err := h.validate.Struct(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Validation failed", Details: err.Error()})
	}

	service, err := h.catalogService.CreateSubscriptionService(c.Context(), req)
	if err != nil {
		if errors.Is(err, services.ErrServiceAlreadyExists) {
			return c.Status(fiber.StatusConflict).JSON(ErrorResponse{Error: err.Error()})
		}
		log.Printf("Error creating subscription service: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to create subscription service"})
	}
	return c.Status(fiber.StatusCreated).JSON(service)
}

// ListSubscriptionServices handles requests to list all available subscription services.
// @Summary List available subscription services
// @Description Retrieves a list of predefined subscription services that users can host.
// @Tags SubscriptionServices
// @Produce json
// @Success 200 {array} models.SubscriptionService "A list of subscription services"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /subscription-services [get]
func (h *SubscriptionServiceHandler) ListSubscriptionServices(c *fiber.Ctx) error {
	servicesList, err := h.catalogService.ListSubscriptionServices(c.Context())
	if err != nil {
		log.Printf("Error listing subscription services: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve subscription services"})
	}
	return c.Status(fiber.StatusOK).JSON(servicesList)
}
