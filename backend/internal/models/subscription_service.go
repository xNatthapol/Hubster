package models

import (
	"time"
)

// SubscriptionService defines a type of subscription service offered.
// @name SubscriptionService
type SubscriptionService struct {
	ID        uint      `gorm:"primarykey" json:"id"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
	Name      string    `gorm:"type:varchar(100);uniqueIndex;not null" json:"name"`
	LogoURL   string    `gorm:"type:text" json:"logo_url,omitempty"`
}

// CreateSubscriptionServiceRequest defines the request body for creating a new subscription service.
// @name CreateSubscriptionServiceRequest
type CreateSubscriptionServiceRequest struct {
	Name    string `json:"name" validate:"required,min=2,max=100"`
	LogoURL string `json:"logo_url" validate:"omitempty,url"`
}
