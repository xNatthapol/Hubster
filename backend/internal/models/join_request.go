package models

import (
	"time"
)

// JoinRequestStatus defines the possible statuses for a join request.
type JoinRequestStatus string

const (
	JoinRequestStatusPending   JoinRequestStatus = "Pending"
	JoinRequestStatusApproved  JoinRequestStatus = "Approved"
	JoinRequestStatusDeclined  JoinRequestStatus = "Declined"
	JoinRequestStatusCancelled JoinRequestStatus = "Cancelled"
)

// JoinRequest represents a user's request to join a HostedSubscription.
// @name JoinRequest
type JoinRequest struct {
	ID        uint      `gorm:"primarykey" json:"id"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`

	RequesterUserID      uint               `gorm:"not null;uniqueIndex:idx_requester_subscription" json:"requester_user_id"`
	User                 User               `gorm:"foreignKey:RequesterUserID" json:"requester_user"`
	HostedSubscriptionID uint               `gorm:"not null;uniqueIndex:idx_requester_subscription" json:"hosted_subscription_id"`
	HostedSubscription   HostedSubscription `gorm:"foreignKey:HostedSubscriptionID" json:"-"`

	RequestDate time.Time         `gorm:"not null" json:"request_date"`
	Status      JoinRequestStatus `gorm:"type:varchar(20);not null;default:'Pending'" json:"status"`
}
