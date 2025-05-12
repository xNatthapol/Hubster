package models

import (
	"time"
)

// PaymentStatusType defines the payment status for a membership slot.
type PaymentStatusType string

const (
	PaymentStatusDue            PaymentStatusType = "PaymentDue"
	PaymentStatusPaid           PaymentStatusType = "Paid"
	PaymentStatusUnpaid         PaymentStatusType = "Unpaid"
	PaymentStatusProofSubmitted PaymentStatusType = "ProofSubmitted"
	PaymentStatusProofDeclined  PaymentStatusType = "ProofDeclined"
)

// SubscriptionMembership links a User to a HostedSubscription they have joined.
// @name SubscriptionMembership
type SubscriptionMembership struct {
	ID                   uint               `gorm:"primarykey" json:"id"`
	CreatedAt            time.Time          `json:"createdAt"`
	UpdatedAt            time.Time          `json:"updatedAt"`
	MemberUserID         uint               `gorm:"not null;uniqueIndex:idx_member_subscription" json:"member_user_id"`
	User                 User               `gorm:"foreignKey:MemberUserID" json:"member_user"`
	HostedSubscriptionID uint               `gorm:"not null;uniqueIndex:idx_member_subscription" json:"hosted_subscription_id"`
	HostedSubscription   HostedSubscription `gorm:"foreignKey:HostedSubscriptionID" json:"-"`
	JoinedDate           time.Time          `gorm:"not null" json:"joined_date"`
	PaymentStatus        PaymentStatusType  `gorm:"type:varchar(50);default:'PaymentDue'" json:"payment_status"`
	NextPaymentDate      *time.Time         `json:"next_payment_date,omitempty"`
	PaymentRecords       []PaymentRecord    `gorm:"foreignKey:SubscriptionMembershipID" json:"-"`
}

// SubscriptionMembershipResponse is the DTO for returning user's membership details.
// @name SubscriptionMembershipResponse
type SubscriptionMembershipResponse struct {
	ID                      uint              `json:"id"`
	MemberUserID            uint              `json:"member_user_id"`
	MemberUser              *UserResponse     `json:"member_user,omitempty"`
	MemberFullName          string            `json:"member_full_name"`
	MemberProfilePictureURL *string           `json:"member_profile_picture_url"`
	HostedSubscriptionID    uint              `json:"hosted_subscription_id"`
	JoinedDate              time.Time         `json:"joined_date"`
	PaymentStatus           PaymentStatusType `json:"payment_status"`
	NextPaymentDate         *time.Time        `json:"next_payment_date,omitempty"`

	// Details from the HostedSubscription
	HostedSubscriptionTitle string  `json:"hosted_subscription_title"`
	ServiceProviderName     string  `json:"service_provider_name"`
	ServiceProviderLogoURL  string  `json:"service_provider_logo_url,omitempty"`
	HostName                string  `json:"host_name"`
	CostPerSlot             float64 `json:"cost_per_slot"`
	PaymentQRCodeURL        string  `json:"payment_qr_code_url,omitempty"`
}
