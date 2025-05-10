package handlers

import (
	"errors"
	"fmt"
	"github.com/xNatthapol/hubster/internal/middleware"
	"github.com/xNatthapol/hubster/internal/services"
	"log"

	"github.com/gofiber/fiber/v2"
)

// UploadResponse defines the structure for a successful upload response
// @name UploadResponse
type UploadResponse struct {
	ImageURL string `json:"image_url"`
}

type UploadHandler struct {
	uploadService services.UploadService
}

func NewUploadHandler(uploadService services.UploadService) *UploadHandler {
	return &UploadHandler{
		uploadService: uploadService,
	}
}

// UploadImage handles uploading an image file via multipart form
// @Summary Upload an image
// @Description Uploads an image file and returns its public URL.
// @Tags Uploads
// @Accept multipart/form-data
// @Produce json
// @Param image formData file true "Image file to upload (JPEG, PNG allowed, max 5MB)"
// @Security BearerAuth
// @Success 200 {object} UploadResponse "Image uploaded successfully"
// @Failure 400 {object} ErrorResponse "Missing file, invalid file type/size"
// @Failure 401 {object} ErrorResponse "Unauthorized (invalid/missing token)"
// @Failure 500 {object} ErrorResponse "Internal server error (file processing, GCS issue, config issue)"
// @Router /uploads/images [post]
func (h *UploadHandler) UploadImage(c *fiber.Ctx) error {
	userID := c.Locals(middleware.UserIDKey).(uint)

	fileHeader, err := c.FormFile("image")
	if err != nil {
		if errors.Is(err, services.ErrGCSConfigMissing) {
			log.Println("ERROR: Handler received no file with key 'image'")
			return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Missing 'image' file in form data"})
		}
		log.Printf("ERROR: Handler error getting file from form: %v", err)
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Could not process file upload"})
	}

	// File Validation max file size 5 MB
	const maxFileSize = 5 * 1024 * 1024
	if fileHeader.Size > maxFileSize {
		log.Printf("WARNING: Upload rejected. File size exceeds limit: %d > %d", fileHeader.Size, maxFileSize)
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: fmt.Sprintf("File size exceeds the limit of %dMB", maxFileSize/1024/1024)})
	}
	contentType := fileHeader.Header.Get("Content-Type")
	allowedTypes := map[string]bool{"image/jpeg": true, "image/png": true}
	if !allowedTypes[contentType] {
		log.Printf("WARNING: Upload rejected. Invalid file content type: %s", contentType)
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Invalid file type. Only JPEG, PNG allowed."})
	}

	imageURL, err := h.uploadService.UploadImage(c.Context(), userID, fileHeader)
	if err != nil {
		log.Printf("ERROR: Service UploadImage failed: %v", err)
		if errors.Is(err, services.ErrGCSConfigMissing) {
			return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Image upload feature not configured"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to upload image"})
	}

	return c.Status(fiber.StatusOK).JSON(UploadResponse{ImageURL: imageURL})
}
