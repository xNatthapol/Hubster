package services

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/xNatthapol/hubster/internal/utils"
	"log"
	"mime/multipart"
	"path/filepath"
)

var (
	ErrGCSConfigMissing = errors.New("GCS configuration is incomplete")
)

type UploadService interface {
	UploadImage(ctx context.Context, userID uint, fileHeader *multipart.FileHeader) (string, error)
}

type uploadService struct {
	uploader *utils.GCSUploader
}

// NewUploadService creates a new upload service instance
func NewUploadService(uploader *utils.GCSUploader) UploadService {
	if uploader == nil {
		log.Println("WARNING: UploadService created without a valid GCS uploader. Uploads will fail.")
		return &uploadService{uploader: nil}
	}
	return &uploadService{uploader: uploader}
}

// UploadImage handles the logic for uploading an image and returning its URL
func (s *uploadService) UploadImage(ctx context.Context, userID uint, fileHeader *multipart.FileHeader) (string, error) {
	// Check if uploader was initialized correctly
	if s.uploader == nil {
		return "", ErrGCSConfigMissing
	}

	file, err := fileHeader.Open()
	if err != nil {
		log.Printf("ERROR: Failed to open uploaded file header in service: %v", err)
		return "", fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	// Generate unique object name
	extension := filepath.Ext(fileHeader.Filename)
	// Store in uploads folder
	objectName := fmt.Sprintf("uploads/%d/%s%s", userID, uuid.NewString(), extension)

	// Determine content type
	contentType := fileHeader.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	// Use the injected uploader instance to upload the file
	imageURL, err := s.uploader.UploadFile(ctx, objectName, file, contentType)
	if err != nil {
		log.Printf("ERROR: Failed to upload file via GCS uploader: %v", err)
		return "", fmt.Errorf("failed to upload image: %w", err)
	}

	return imageURL, nil
}
