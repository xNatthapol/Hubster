package models

import (
	"time"
)

// BillingCycleType defines the allowed values for billing cycles.
type BillingCycleType string

const (
	BillingMonthly  BillingCycleType = "Monthly"
	BillingAnnually BillingCycleType = "Annually"
)

// HostedSubscription represents a subscription plan offered for sharing by a host.
// @name HostedSubscription
type HostedSubscription struct {
	ID                    uint                     `gorm:"primarykey" json:"id"`
	CreatedAt             time.Time                `json:"createdAt"`
	UpdatedAt             time.Time                `json:"updatedAt"`
	HostUserID            uint                     `gorm:"not null" json:"host_user_id"`
	User                  User                     `gorm:"foreignKey:HostUserID" json:"-"`
	SubscriptionServiceID uint                     `gorm:"not null" json:"subscription_service_id"`
	SubscriptionService   SubscriptionService      `gorm:"foreignKey:SubscriptionServiceID" json:"-"`
	SubscriptionTitle     string                   `gorm:"type:varchar(255);not null" json:"subscription_title"`
	PlanDetails           string                   `gorm:"type:text" json:"plan_details,omitempty"`
	TotalSlots            int                      `gorm:"not null" json:"total_slots"`
	CostPerCycle          float64                  `gorm:"not null" json:"cost_per_cycle"`
	BillingCycle          BillingCycleType         `gorm:"type:varchar(20);not null" json:"billing_cycle"`
	PaymentQRCodeURL      string                   `gorm:"type:text" json:"payment_qr_code_url,omitempty"`
	Description           string                   `gorm:"type:text" json:"description,omitempty"`
	Memberships           []SubscriptionMembership `gorm:"foreignKey:HostedSubscriptionID" json:"-"`
}

// CreateHostedSubscriptionRequest defines the request body for creating a new hosted subscription.
// @name CreateHostedSubscriptionRequest
type CreateHostedSubscriptionRequest struct {
	SubscriptionServiceID uint             `json:"subscription_service_id" validate:"required,gt=0"`
	SubscriptionTitle     string           `json:"subscription_title" validate:"required,min=3,max=100"`
	PlanDetails           string           `json:"plan_details,omitempty" validate:"max=255"`
	TotalSlots            int              `json:"total_slots" validate:"required,min=1,max=20"`
	CostPerCycle          float64          `json:"cost_per_cycle" validate:"required,gt=0"`
	BillingCycle          BillingCycleType `json:"billing_cycle" validate:"required,oneof=Monthly Annually"`
	PaymentQRCodeURL      string           `json:"payment_qr_code_url" validate:"omitempty,url"`
	Description           string           `json:"description,omitempty" validate:"max=1000"`
}

// HostedSubscriptionResponse is the DTO for returning hosted subscription details.
// @name HostedSubscriptionResponse
type HostedSubscriptionResponse struct {
	ID                uint             `json:"id"`
	Host              *UserResponse    `json:"host,omitempty"`
	SubscriptionTitle string           `json:"subscription_title"`
	PlanDetails       string           `json:"plan_details,omitempty"`
	TotalSlots        int              `json:"total_slots"`
	CostPerCycle      float64          `json:"cost_per_cycle"`
	BillingCycle      BillingCycleType `json:"billing_cycle"`
	PaymentQRCodeURL  string           `json:"payment_qr_code_url,omitempty"`
	Description       string           `json:"description,omitempty"`
	CreatedAt         time.Time        `json:"createdAt"`
	UpdatedAt         time.Time        `json:"updatedAt"`

	// Enriched / Calculated data
	SubscriptionServiceName string   `json:"subscription_service_name"`
	SubscriptionServiceLogo string   `json:"subscription_service_logo_url,omitempty"`
	MembersCount            int      `json:"members_count"`
	AvailableSlots          int      `json:"available_slots"`
	CostPerSlot             float64  `json:"cost_per_slot"`
	MemberAvatars           []string `json:"member_avatars,omitempty"`
}

// UserResponse is a DTO for user details included in other responses.
// @name UserResponse
type UserResponse struct {
	ID                uint    `json:"id"`
	Email             string  `json:"email"`
	FullName          string  `json:"full_name"`
	ProfilePictureURL *string `json:"profile_picture_url,omitempty"`
}
