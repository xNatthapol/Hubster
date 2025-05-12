package models

import (
	"time"
)

// PaymentRecordStatus defines the status of a payment record/submission.
type PaymentRecordStatus string

const (
	PaymentRecordStatusProofSubmitted    PaymentRecordStatus = "ProofSubmitted"
	PaymentRecordStatusApproved          PaymentRecordStatus = "Approved"
	PaymentRecordStatusDeclined          PaymentRecordStatus = "Declined"
	PaymentRecordStatusRequiresAttention PaymentRecordStatus = "RequiresAttention"
)

// PaymentRecord stores information about a payment made by a member for a subscription slot.
// @name PaymentRecord
type PaymentRecord struct {
	ID        uint      `gorm:"primarykey" json:"id"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`

	SubscriptionMembershipID uint                   `gorm:"not null" json:"subscription_membership_id"`
	SubscriptionMembership   SubscriptionMembership `gorm:"foreignKey:SubscriptionMembershipID" json:"-"`
	PaymentCycleIdentifier   string                 `gorm:"type:varchar(100);not null" json:"payment_cycle_identifier"`
	AmountExpected           float64                `gorm:"not null" json:"amount_expected"`
	AmountPaid               float64                `gorm:"not null" json:"amount_paid"`
	PaymentMethod            string                 `gorm:"type:varchar(100)" json:"payment_method,omitempty"`
	TransactionReference     string                 `gorm:"type:varchar(255)" json:"transaction_reference,omitempty"`
	ProofImageURL            string                 `gorm:"type:text;not null" json:"proof_image_url"`
	SubmittedAt              time.Time              `gorm:"not null" json:"submitted_at"`
	Status                   PaymentRecordStatus    `gorm:"type:varchar(50);not null" json:"status"`
	ReviewedByUserID         *uint                  `json:"reviewed_by_user_id,omitempty"`
	ReviewedAt               *time.Time             `json:"reviewed_at,omitempty"`
}

// CreatePaymentRecordRequest defines the request body for a member submitting payment proof.
// @name CreatePaymentRecordRequest
type CreatePaymentRecordRequest struct {
	PaymentCycleIdentifier string  `json:"payment_cycle_identifier" validate:"required,min=3,max=100"`
	AmountPaid             float64 `json:"amount_paid" validate:"required,gt=0"`
	ProofImageURL          string  `json:"proof_image_url" validate:"required,url"`
	PaymentMethod          string  `json:"payment_method,omitempty" validate:"max=100"`
	TransactionReference   string  `json:"transaction_reference,omitempty" validate:"max=255"`
}
