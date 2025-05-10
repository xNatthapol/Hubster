package handlers

import (
	"github.com/xNatthapol/hubster/internal/config"
	"github.com/xNatthapol/hubster/internal/middleware"

	_ "github.com/xNatthapol/hubster/docs"

	fiberSwagger "github.com/swaggo/fiber-swagger"

	"github.com/gofiber/fiber/v2"
)

func SetupRoutes(app *fiber.App, authHandler *AuthHandler, uploadHandler *UploadHandler, cfg *config.Config) {
	// Swagger Documentation Route
	app.Get("/swagger/*", fiberSwagger.WrapHandler)

	api := app.Group("/api")

	// Auth Routes
	auth := api.Group("/auth")
	auth.Post("/signup", authHandler.SignUp)
	auth.Post("/login", authHandler.Login)
	auth.Get("/me", middleware.Protected(cfg), authHandler.GetMe)

	// Upload Route
	uploads := api.Group("/uploads", middleware.Protected(cfg))
	uploads.Post("/images", uploadHandler.UploadImage)
}
