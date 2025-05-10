package config

import (
	"fmt"
	"log"
	"time"

	"github.com/joho/godotenv"
	"github.com/spf13/viper"
)

const insecureDefaultJwtSecret = "insecure_jwt_secret_key_for_dev_only"

type Config struct {
	ServerPort               string        `mapstructure:"SERVER_PORT"`
	DBHost                   string        `mapstructure:"DB_HOST"`
	DBPort                   string        `mapstructure:"DB_PORT"`
	DBUser                   string        `mapstructure:"DB_USER"`
	DBPassword               string        `mapstructure:"DB_PASSWORD"`
	DBName                   string        `mapstructure:"DB_NAME"`
	DBSSLMode                string        `mapstructure:"DB_SSLMODE"`
	TimeZone                 string        `mapstructure:"TIME_ZONE"`
	PgAdminEmail             string        `mapstructure:"PGADMIN_DEFAULT_EMAIL"`
	PgAdminPassword          string        `mapstructure:"PGADMIN_DEFAULT_PASSWORD"`
	JWTSecret                string        `mapstructure:"JWT_SECRET"`
	JWTExpiresInDuration     time.Duration `mapstructure:"JWT_EXPIRES_IN_MINUTES"`
	CORSAllowedOrigins       string        `mapstructure:"CORS_ALLOWED_ORIGINS"`
	GCSBucketName            string        `mapstructure:"GCS_BUCKET_NAME"`
	GCSServiceAccountKeyPath string        `mapstructure:"GCS_SERVICE_ACCOUNT_KEY_PATH"`
}

var AppConfig *Config

func LoadConfig(path string) (*Config, error) {
	_ = godotenv.Load(path + "/.env")

	viper.AddConfigPath(path)
	viper.SetConfigName(".env")
	viper.SetConfigType("env")
	viper.AutomaticEnv()

	viper.SetDefault("SERVER_PORT", "8080")
	viper.SetDefault("DB_HOST", "localhost")
	viper.SetDefault("DB_PORT", "5432")
	viper.SetDefault("DB_USER", "postgres")
	viper.SetDefault("DB_PASSWORD", "postgres")
	viper.SetDefault("DB_NAME", "hubster_db")
	viper.SetDefault("DB_SSLMODE", "disable")
	viper.SetDefault("TIME_ZONE", "Asia/Bangkok")
	viper.SetDefault("JWT_SECRET", insecureDefaultJwtSecret)
	viper.SetDefault("JWT_EXPIRES_IN_MINUTES", "60m")
	viper.SetDefault("CORS_ALLOWED_ORIGINS", "*")

	if err := viper.ReadInConfig(); err == nil {
		log.Println("INFO: Config file loaded successfully.")
	} else if _, ok := err.(viper.ConfigFileNotFoundError); ok {
		log.Println("WARNING: Config file not found. Using environment variables and default values.")
	} else {
		log.Printf("WARNING: Failed to read config file: %v", err)
	}

	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		log.Printf("Error unmarshalling config: %v", err)
		return nil, fmt.Errorf("failed to unmarshal configuration: %w", err)
	}

	if cfg.JWTSecret == insecureDefaultJwtSecret {
		log.Printf("!! WARNING: Using default insecure JWT_SECRET ('%s'). Set a proper secret in .env or environment variable for security. !!", insecureDefaultJwtSecret)
	}

	if cfg.GCSBucketName == "" || cfg.GCSServiceAccountKeyPath == "" {
		log.Println("WARNING: GCS_BUCKET_NAME or GCS_SERVICE_ACCOUNT_KEY_PATH not configured. Image upload functionality will be disabled.")
	}

	AppConfig = &cfg
	log.Printf("INFO: Configuration loaded successfully.")

	return &cfg, nil
}
