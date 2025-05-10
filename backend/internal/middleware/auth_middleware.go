package middleware

import (
	"github.com/xNatthapol/hubster/internal/config"
	"github.com/xNatthapol/hubster/internal/utils"
	"strings"

	"github.com/gofiber/fiber/v2"
)

const (
	AuthorizationHeaderKey = "Authorization"
	BearerSchema           = "Bearer"
	UserIDKey              = "userID"
)

func Protected(cfg *config.Config) fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get(AuthorizationHeaderKey)
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Missing authorization header"})
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != BearerSchema {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid authorization format (Bearer token expected)"})
		}

		tokenString := parts[1]
		claims, err := utils.ValidateJWT(tokenString, cfg)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid or expired token", "details": err.Error()})
		}

		// Set user ID in context locals for handlers to access
		c.Locals(UserIDKey, claims.UserID)

		return c.Next()
	}
}
