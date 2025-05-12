package handlers

import (
	"errors"
	"log"
	"strconv"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/xNatthapol/hubster/internal/middleware"
	"github.com/xNatthapol/hubster/internal/models"
	"github.com/xNatthapol/hubster/internal/services"
)

// PaymentHandler handles requests related to payments and payment proofs.
type PaymentHandler struct {
	paymentService services.PaymentService
	validate       *validator.Validate
}

// NewPaymentHandler creates a new PaymentHandler.
func NewPaymentHandler(paymentService services.PaymentService) *PaymentHandler {
	return &PaymentHandler{
		paymentService: paymentService,
		validate:       validator.New(),
	}
}

// SubmitPaymentProof handles a member submitting their payment proof for a membership.
// @Summary Submit payment proof for a subscription membership
// @Description Allows an authenticated member to submit proof of payment for a specific subscription membership they are part of.
// @Tags Payments
// @Accept json
// @Produce json
// @Param membershipId path int true "ID of the Subscription Membership"
// @Param payment_details body models.CreatePaymentRecordRequest true "Details of the payment and proof"
// @Security BearerAuth
// @Success 201 {object} models.PaymentRecord "Payment proof submitted successfully"
// @Failure 400 {object} ErrorResponse "Invalid input or validation error"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden (e.g., user is not the member of this slot)"
// @Failure 404 {object} ErrorResponse "Subscription membership not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /memberships/{membershipId}/payment-records [post]
func (h *PaymentHandler) SubmitPaymentProof(c *fiber.Ctx) error {
	memberUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized: Invalid user context"})
	}

	membershipIDStr := c.Params("membershipId")
	membershipID, err := strconv.ParseUint(membershipIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid membership ID format"})
	}

	req := new(models.CreatePaymentRecordRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Cannot parse JSON request body"})
	}
	if err := h.validate.Struct(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Validation failed", Details: err.Error()})
	}

	paymentRecord, err := h.paymentService.SubmitPaymentProof(c.Context(), memberUserID, uint(membershipID), req)
	if err != nil {
		switch {
		case errors.Is(err, services.ErrMembershipNotFound):
			return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{Error: err.Error()})
		case errors.Is(err, services.ErrNotMember):
			return c.Status(fiber.StatusForbidden).JSON(ErrorResponse{Error: err.Error()})
		default:
			log.Printf("Error submitting payment proof for membership %d by user %d: %v", membershipID, memberUserID, err)
			return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to submit payment proof"})
		}
	}

	return c.Status(fiber.StatusCreated).JSON(paymentRecord)
}

// ListPaymentRecordsForHostedSubscription handles hosts viewing payment records for their subscription.
// @Summary List payment records for a hosted subscription
// @Description Retrieves payment records for a specific subscription owned by the host, filterable by status.
// @Tags Payments
// @Produce json
// @Param subscriptionId path int true "ID of the Hosted Subscription"
// @Param status query string false "Filter by payment record status (e.g., ProofSubmitted)" Enums(ProofSubmitted,Approved,Declined,RequiresAttention)
// @Security BearerAuth
// @Success 200 {array} models.PaymentRecordResponse "A list of payment records"
// @Failure 400 {object} ErrorResponse "Invalid ID or status format"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden (not the host)"
// @Failure 404 {object} ErrorResponse "Subscription not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /hosted-subscriptions/{subscriptionId}/payment-records [get]
func (h *PaymentHandler) ListPaymentRecordsForHostedSubscription(c *fiber.Ctx) error {
	hostUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized"})
	}
	subscriptionIDStr := c.Params("subscriptionId")
	subscriptionID, err := strconv.ParseUint(subscriptionIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid subscription ID format"})
	}

	statusQuery := c.Query("status")
	if statusQuery == "" {
		statusQuery = string(models.PaymentRecordStatusProofSubmitted)
	}
	status := models.PaymentRecordStatus(statusQuery)

	records, err := h.paymentService.ListPaymentRecordsForHost(c.Context(), hostUserID, uint(subscriptionID), status)
	if err != nil {
		log.Printf("Error listing payment records for host %d, sub %d: %v", hostUserID, subscriptionID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve payment records"})
	}
	if records == nil {
		records = []models.PaymentRecordResponse{}
	}
	return c.Status(fiber.StatusOK).JSON(records)
}

// GetPaymentRecord handles fetching a specific payment record.
// @Summary Get a specific payment record
// @Description Retrieves details of a specific payment record. Accessible by host or submitting member.
// @Tags Payments
// @Produce json
// @Param id path int true "Payment Record ID"
// @Security BearerAuth
// @Success 200 {object} models.PaymentRecordResponse "Payment record details"
// @Failure 400 {object} ErrorResponse "Invalid ID format"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden"
// @Failure 404 {object} ErrorResponse "Payment record not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /payment-records/{id} [get]
func (h *PaymentHandler) GetPaymentRecord(c *fiber.Ctx) error {
	accessorUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized"})
	}

	prIDStr := c.Params("id")
	prID, err := strconv.ParseUint(prIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid payment record ID"})
	}

	paymentRecord, err := h.paymentService.GetPaymentRecordDetails(c.Context(), uint(prID), accessorUserID, true)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to get payment record"})
	}
	return c.Status(fiber.StatusOK).JSON(paymentRecord)
}

// ApprovePaymentProof handles a host approving a payment proof.
// @Summary Approve a payment proof
// @Description Allows a host to approve a submitted payment proof.
// @Tags Payments
// @Produce json
// @Param id path int true "Payment Record ID"
// @Security BearerAuth
// @Success 200 {object} models.PaymentRecordResponse "Payment proof approved"
// @Failure 400 {object} ErrorResponse "Invalid ID or record not modifiable"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden"
// @Failure 404 {object} ErrorResponse "Payment record not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /payment-records/{id}/approve [patch]
func (h *PaymentHandler) ApprovePaymentProof(c *fiber.Ctx) error {
	hostUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized"})
	}

	prIDStr := c.Params("id")
	prID, err := strconv.ParseUint(prIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid payment record ID"})
	}

	paymentRecord, err := h.paymentService.ApprovePaymentProof(c.Context(), hostUserID, uint(prID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to approve payment proof"})
	}
	return c.Status(fiber.StatusOK).JSON(paymentRecord)
}

// DeclinePaymentProof handles a host declining a payment proof.
// @Summary Decline a payment proof
// @Description Allows a host to decline a submitted payment proof, with optional notes.
// @Tags Payments
// @Produce json
// @Param id path int true "Payment Record ID"
// @Security BearerAuth
// @Success 200 {object} models.PaymentRecordResponse "Payment proof declined"
// @Failure 400 {object} ErrorResponse "Invalid ID, record not modifiable, or notes missing if required"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden"
// @Failure 404 {object} ErrorResponse "Payment record not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /payment-records/{id}/decline [patch]
func (h *PaymentHandler) DeclinePaymentProof(c *fiber.Ctx) error {
	hostUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized"})
	}

	prIDStr := c.Params("id")
	prID, err := strconv.ParseUint(prIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid payment record ID"})
	}

	paymentRecord, err := h.paymentService.DeclinePaymentProof(c.Context(), hostUserID, uint(prID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to decline payment proof"})
	}
	return c.Status(fiber.StatusOK).JSON(paymentRecord)
}

// ListMyPaymentRecordsForMembership handles a member viewing their payment history for a specific membership.
// @Summary List my payment records for a membership
// @Description Retrieves the payment history for a specific subscription membership the user is part of.
// @Tags Payments
// @Produce json
// @Param membershipId path int true "ID of the Subscription Membership"
// @Security BearerAuth
// @Success 200 {array} models.PaymentRecord "A list of payment records for the membership"
// @Failure 400 {object} ErrorResponse "Invalid membership ID format"
// @Failure 401 {object} ErrorResponse "Unauthorized"
// @Failure 403 {object} ErrorResponse "Forbidden (not a member of this subscription)"
// @Failure 404 {object} ErrorResponse "Membership not found"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /memberships/{membershipId}/payment-records [get]
func (h *PaymentHandler) ListMyPaymentRecordsForMembership(c *fiber.Ctx) error {
	memberUserID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized"})
	}

	membershipIDStr := c.Params("membershipId")
	membershipID, err := strconv.ParseUint(membershipIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid membership ID format"})
	}

	records, err := h.paymentService.ListPaymentRecordsForMembership(c.Context(), memberUserID, uint(membershipID))
	if err != nil {
		if errors.Is(err, services.ErrMembershipNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{Error: err.Error()})
		}
		if errors.Is(err, services.ErrForbidden) {
			return c.Status(fiber.StatusForbidden).JSON(ErrorResponse{Error: err.Error()})
		}
		log.Printf("Error listing payment records for membership %d by user %d: %v", membershipID, memberUserID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to retrieve payment history"})
	}

	if records == nil {
		records = []models.PaymentRecord{}
	}
	return c.Status(fiber.StatusOK).JSON(records)
}
