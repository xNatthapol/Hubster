package handlers

import (
	"errors"
	"github.com/xNatthapol/hubster/internal/middleware"
	"github.com/xNatthapol/hubster/internal/models"
	"github.com/xNatthapol/hubster/internal/services"
	"log"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct {
	authService services.AuthService
	validate    *validator.Validate
}

func NewAuthHandler(authService services.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		validate:    validator.New(),
	}
}

// SignUpRequest defines the request body for user sign up
// @name SignUpRequest
type SignUpRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=6"`
	FullName string `json:"full_name" validate:"required,min=2,max=100"`
}

// LoginRequest defines the request body for user login
// @name LoginRequest
type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

// AuthResponse defines the successful authentication response
// @name AuthResponse
type AuthResponse struct {
	Token string       `json:"token"`
	User  *models.User `json:"user"`
}

// SignUp handles for user sign up
// @Summary Sign up a new user
// @Description Creates a new user account.
// @Tags Auth
// @Accept json
// @Produce json
// @Param user body SignUpRequest true "User sign up details"
// @Success 201 {object} models.User "User created successfully (excluding password)"
// @Failure 400 {object} ErrorResponse "Validation error or invalid input"
// @Failure 409 {object} ErrorResponse "User with this email already exists"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /auth/signup [post]
func (h *AuthHandler) SignUp(c *fiber.Ctx) error {
	req := new(SignUpRequest)

	if err := c.BodyParser(req); err != nil {
		log.Printf("Error parsing sign up request body: %v", err)
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Cannot parse JSON"})
	}

	if err := h.validate.Struct(req); err != nil {
		log.Printf("Validation error during sign up: %v", err)
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Validation failed", Details: err.Error()})
	}

	user, err := h.authService.SignUpUser(c.Context(), req.Email, req.Password, req.FullName)
	if err != nil {
		log.Printf("Error sign up user: %v", err)
		if errors.Is(err, services.ErrUserAlreadyExists) {
			return c.Status(fiber.StatusConflict).JSON(ErrorResponse{Error: err.Error()})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to sign up user"})
	}

	return c.Status(fiber.StatusCreated).JSON(user)
}

// Login handles user login
// @Summary Log in a user
// @Description Authenticates a user and returns a JWT token.
// @Tags Auth
// @Accept json
// @Produce json
// @Param credentials body LoginRequest true "User login credentials"
// @Success 200 {object} AuthResponse "Login successful"
// @Failure 400 {object} ErrorResponse "Validation error or invalid input"
// @Failure 401 {object} ErrorResponse "Invalid credentials"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /auth/login [post]
func (h *AuthHandler) Login(c *fiber.Ctx) error {
	req := new(LoginRequest)

	if err := c.BodyParser(req); err != nil {
		log.Printf("Error parsing login request body: %v", err)
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Cannot parse JSON"})
	}

	if err := h.validate.Struct(req); err != nil {
		log.Printf("Validation error during login: %v", err)
		return c.Status(fiber.StatusBadRequest).JSON(ErrorResponse{Error: "Validation failed", Details: err.Error()})
	}

	token, user, err := h.authService.LoginUser(c.Context(), req.Email, req.Password)
	if err != nil {
		log.Printf("Error logging in user %s: %v", req.Email, err)
		if errors.Is(err, services.ErrInvalidCredentials) {
			return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: err.Error()})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Failed to login user"})
	}

	return c.Status(fiber.StatusOK).JSON(AuthResponse{
		Token: token,
		User:  user,
	})
}

// GetMe retrieves the currently authenticated user's details.
// @Summary Get current user
// @Description Retrieves details of the logged-in user based on JWT.
// @Tags Auth
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.User "User details (excluding password)"
// @Failure 401 {object} ErrorResponse "Unauthorized (invalid/missing token)"
// @Failure 404 {object} ErrorResponse "User not found (e.g., token valid but user deleted)"
// @Failure 500 {object} ErrorResponse "Internal server error"
// @Router /auth/me [get]
func (h *AuthHandler) GetMe(c *fiber.Ctx) error {
	userID, ok := c.Locals(middleware.UserIDKey).(uint)
	if !ok {
		log.Println("Error: UserIDKey not found in context or not of type uint in GetMe")
		return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{Error: "Unauthorized: Invalid token context"})
	}

	user, err := h.authService.GetUserByID(c.Context(), userID)
	if err != nil {
		if errors.Is(err, services.ErrUserNotFound) {
			log.Printf("GetMe: User with ID %d not found (token might be for a deleted user)", userID)
			return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{Error: "User not found"})
		}
		log.Printf("GetMe: Error retrieving user %d: %v", userID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{Error: "Could not retrieve user information"})
	}

	// user.Password is already "" from GetUserByID
	return c.Status(fiber.StatusOK).JSON(user)
}

// ErrorResponse defines the standard error response format
// @name ErrorResponse
type ErrorResponse struct {
	Error   string `json:"error"`
	Details string `json:"details,omitempty"`
}
