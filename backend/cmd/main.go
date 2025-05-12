package main

import (
	"context"
	"log"

	"github.com/xNatthapol/hubster/internal/config"
	"github.com/xNatthapol/hubster/internal/database"
	"github.com/xNatthapol/hubster/internal/handlers"
	"github.com/xNatthapol/hubster/internal/repositories"
	"github.com/xNatthapol/hubster/internal/services"
	"github.com/xNatthapol/hubster/internal/utils"

	_ "github.com/xNatthapol/hubster/docs"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
)

// @title Hubster Application API
// @version 1.0
// @description This is a Hubster application API server.
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url http://www.swagger.io/support
// @contact.email support@swagger.io

// @license.name Apache 2.0
// @license.url http://www.apache.org/licenses/LICENSE-2.0.html

// @host localhost:8080
// @BasePath /api
// @schemes http https
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.
func main() {
	cfg, err := config.LoadConfig(".")
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	db, err := database.ConnectDB(cfg)
	if err != nil {
		log.Fatalf("FATAL: Failed to initialize database: %v", err)
	}

	var gcsUploader *utils.GCSUploader
	if cfg.GCSBucketName != "" && cfg.GCSServiceAccountKeyPath != "" {
		uploader, err := utils.NewGCSUploader(context.Background(), cfg.GCSBucketName, cfg.GCSServiceAccountKeyPath)
		if err != nil {
			log.Printf("WARNING: Failed to initialize GCS Uploader: %v. Image uploads disabled.", err)
			gcsUploader = nil
		} else {
			gcsUploader = uploader
			// Defer closing the GCS client
			defer func() {
				if err := gcsUploader.Close(); err != nil {
					log.Printf("ERROR: Failed to close GCS client: %v", err)
				}
			}()
		}
	} else {
		gcsUploader = nil
	}

	userRepo := repositories.NewUserRepository(db)
	subscriptionServiceRepo := repositories.NewSubscriptionServiceRepository(db)
	hostedSubRepo := repositories.NewHostedSubscriptionRepository(db)
	membershipRepo := repositories.NewSubscriptionMembershipRepository(db)
	joinRequestRepo := repositories.NewJoinRequestRepository(db) // Add this
	paymentRecordRepo := repositories.NewPaymentRecordRepository(db)

	authService := services.NewAuthService(userRepo, cfg)
	userService := services.NewUserService(userRepo)
	uploadService := services.NewUploadService(gcsUploader)
	subscriptionCatalogService := services.NewSubscriptionCatalogService(subscriptionServiceRepo)
	hostedSubService := services.NewHostedSubscriptionService(
		hostedSubRepo,
		joinRequestRepo,
		membershipRepo,
		subscriptionServiceRepo,
		userRepo,
	)
	paymentService := services.NewPaymentService(paymentRecordRepo, membershipRepo, hostedSubRepo)

	authHandler := handlers.NewAuthHandler(authService)
	userHandler := handlers.NewUserHandler(userService, hostedSubService)
	uploadHandler := handlers.NewUploadHandler(uploadService)
	subscriptionServiceHandler := handlers.NewSubscriptionServiceHandler(subscriptionCatalogService)
	hostedSubHandler := handlers.NewHostedSubscriptionHandler(hostedSubService)
	paymentHandler := handlers.NewPaymentHandler(paymentService)

	app := fiber.New(fiber.Config{
		AppName: "Hubster App",
	})

	app.Use(cors.New(cors.Config{
		AllowOrigins: cfg.CORSAllowedOrigins,
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PUT, PATCH, DELETE, OPTIONS",
	}))
	app.Use(logger.New())

	handlers.SetupRoutes(
		app,
		authHandler,
		userHandler,
		uploadHandler,
		subscriptionServiceHandler,
		hostedSubHandler,
		paymentHandler,
		cfg)

	log.Printf("INFO: Starting server on port %s", cfg.ServerPort)
	if err := app.Listen(":" + cfg.ServerPort); err != nil {
		log.Fatalf("FATAL: Server failed to start: %v", err)
	}
}
