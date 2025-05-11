package models

import (
	"time"
)

// User defines the user model
// @name User
type User struct {
	ID                uint      `gorm:"primarykey" json:"id"`
	CreatedAt         time.Time `json:"createdAt"`
	UpdatedAt         time.Time `json:"updatedAt"`
	Email             string    `gorm:"uniqueIndex;not null" json:"email"`
	Password          string    `gorm:"not null" json:"-"` // '-' hides password in JSON responses
	FullName          string    `gorm:"type:varchar(255);not null" json:"full_name"`
	ProfilePictureURL *string   `gorm:"type:text" json:"profile_picture_url,omitempty"`
	PhoneNumber       *string   `gorm:"type:varchar(30)" json:"phone_number,omitempty"`
}

// UpdateUserRequest defines the structure for updating user profile
// @name UpdateUserRequest
type UpdateUserRequest struct {
	FullName          *string `json:"full_name,omitempty" validate:"omitempty,min=2,max=100"`
	ProfilePictureURL *string `json:"profile_picture_url,omitempty" validate:"omitempty,url"`
	PhoneNumber       *string `json:"phone_number,omitempty" validate:"omitempty,e164"`
}
