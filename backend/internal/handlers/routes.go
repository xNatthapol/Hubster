package handlers

import (
	"github.com/xNatthapol/hubster/internal/config"
	"github.com/xNatthapol/hubster/internal/middleware"

	_ "github.com/xNatthapol/hubster/docs"

	fiberSwagger "github.com/swaggo/fiber-swagger"

	"github.com/gofiber/fiber/v2"
)

// SetupRoutes configures all the application's HTTP routes.
func SetupRoutes(
	app *fiber.App,
	authHandler *AuthHandler,
	userHandler *UserHandler,
	uploadHandler *UploadHandler,
	subscriptionServiceHandler *SubscriptionServiceHandler,
	hostedSubHandler *HostedSubscriptionHandler,
	paymentHandler *PaymentHandler,
	cfg *config.Config,
) {

	// Swagger UI route
	app.Get("/swagger/*", fiberSwagger.WrapHandler)

	// API grouping
	api := app.Group("/api")

	// Authentication routes
	authGroup := api.Group("/auth")
	authGroup.Post("/signup", authHandler.SignUp)
	authGroup.Post("/login", authHandler.Login)
	authGroup.Get("/me", middleware.Protected(cfg), authHandler.GetMe)

	// User specific routes
	currentUserGroup := api.Group("/users/me", middleware.Protected(cfg))
	currentUserGroup.Patch("/profile", userHandler.UpdateCurrentUserProfile)
	currentUserGroup.Get("/hosted-subscriptions", hostedSubHandler.ListUserHostedSubscriptions)
	currentUserGroup.Get("/join-requests", userHandler.ListMyJoinRequests)
	currentUserGroup.Get("/memberships", userHandler.ListMyMemberships)

	// Subscription Services Catalog routes
	serviceCatalogGroup := api.Group("/subscription-services")
	serviceCatalogGroup.Get("/", subscriptionServiceHandler.ListSubscriptionServices)
	serviceCatalogGroup.Post("/add", middleware.Protected(cfg), subscriptionServiceHandler.CreateSubscriptionService)

	// Hosted Subscriptions routes
	hostedSubscriptionsGroup := api.Group("/hosted-subscriptions", middleware.Protected(cfg))
	hostedSubscriptionsGroup.Post("/", hostedSubHandler.CreateHostedSubscription)
	hostedSubscriptionsGroup.Get("/", hostedSubHandler.ExploreAllHostedSubscriptions)
	hostedSubscriptionsGroup.Get("/:id", hostedSubHandler.GetHostedSubscriptionDetails)
	hostedSubscriptionsGroup.Post("/:id/join-requests", hostedSubHandler.CreateJoinRequest)
	hostedSubscriptionsGroup.Get("/:subscriptionId/join-requests", hostedSubHandler.ListJoinRequestsForSubscription)
	hostedSubscriptionsGroup.Get("/:subscriptionId/members", hostedSubHandler.ListSubscriptionMembers)
	hostedSubscriptionsGroup.Get("/:subscriptionId/payment-records", paymentHandler.ListPaymentRecordsForHostedSubscription)

	// Join Requests management routes
	joinRequestsGroup := api.Group("/join-requests", middleware.Protected(cfg))
	joinRequestsGroup.Patch("/:requestId/approve", hostedSubHandler.ApproveJoinRequest)
	joinRequestsGroup.Patch("/:requestId/decline", hostedSubHandler.DeclineJoinRequest)

	// Subscription Memberships routes
	membershipsGroup := api.Group("/memberships", middleware.Protected(cfg))
	membershipsGroup.Post("/:membershipId/payment-records", paymentHandler.SubmitPaymentProof)
	membershipsGroup.Get("/:membershipId/payment-records", paymentHandler.ListMyPaymentRecordsForMembership)

	// Payment Records routes
	paymentRecordsGroup := api.Group("/payment-records", middleware.Protected(cfg))
	paymentRecordsGroup.Get("/:id", paymentHandler.GetPaymentRecord)
	paymentRecordsGroup.Patch("/:id/approve", paymentHandler.ApprovePaymentProof)
	paymentRecordsGroup.Patch("/:id/decline", paymentHandler.DeclinePaymentProof)

	// Image Upload route
	uploadsGroup := api.Group("/uploads", middleware.Protected(cfg))
	uploadsGroup.Post("/images", uploadHandler.UploadImage)
}
