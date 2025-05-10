package utils

import (
	"context"
	"fmt"
	"io"
	"log"
	"time"

	"cloud.google.com/go/storage"
	"google.golang.org/api/option"
)

type GCSUploader struct {
	Client     *storage.Client
	BucketName string
}

// NewGCSUploader creates a new GCS client and uploader instance.
func NewGCSUploader(ctx context.Context, bucketName, keyFilePath string) (*GCSUploader, error) {
	if keyFilePath == "" {
		return nil, fmt.Errorf("GCS service account key path is required")
	}
	if bucketName == "" {
		return nil, fmt.Errorf("GCS bucket name is required")
	}

	client, err := storage.NewClient(ctx, option.WithCredentialsFile(keyFilePath))
	if err != nil {
		return nil, fmt.Errorf("storage.NewClient: %w", err)
	}
	log.Println("INFO: Google Cloud Storage client initialized successfully.")

	return &GCSUploader{
		Client:     client,
		BucketName: bucketName,
	}, nil
}

// UploadFile uploads a file reader to GCS and returns the public URL.
func (g *GCSUploader) UploadFile(ctx context.Context, objectName string, fileReader io.Reader, contentType string) (string, error) {
	if g.Client == nil {
		return "", fmt.Errorf("GCS client is not initialized")
	}

	uploadCtx, cancel := context.WithTimeout(ctx, time.Second*60) // 60-second timeout
	defer cancel()

	obj := g.Client.Bucket(g.BucketName).Object(objectName)
	writer := obj.NewWriter(uploadCtx)

	writer.ContentType = contentType
	writer.CacheControl = "public, max-age=31536000" // Cache for 1 year

	if _, err := io.Copy(writer, fileReader); err != nil {
		return "", fmt.Errorf("io.Copy to GCS: %w", err)
	}

	if err := writer.Close(); err != nil {
		return "", fmt.Errorf("GCS Writer.Close: %w", err)
	}

	opts := &storage.SignedURLOptions{
		Scheme:  storage.SigningSchemeV4,
		Method:  "GET",
		Expires: time.Now().Add(168 * time.Hour),
	}

	url, err := g.Client.Bucket(g.BucketName).SignedURL(objectName, opts)
	if err != nil {
		log.Printf("ERROR: Failed to generate signed URL for object '%s' in bucket '%s': %v", objectName, g.BucketName, err)
		return "", fmt.Errorf("failed to generate GCS signed URL for object '%s': %w", objectName, err)
	}

	return url, nil
}

// Close releases resources associated with the GCS client.
func (g *GCSUploader) Close() error {
	if g.Client != nil {
		log.Println("INFO: Closing GCS client.")
		return g.Client.Close()
	}
	return nil
}
