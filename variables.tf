variable "postgres_password" {
  description = "The password for the PostgreSQL administrator user."
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "postgres_admin" {
  description = "The administrator username for the PostgreSQL server."
  type        = string
  default     = "postgres"
}

variable "database_name" {
  description = "The name of the PostgreSQL database."
  type        = string
  default     = "gotripdb"
}

variable "location" {
  description = "The Azure region for resources."
  type        = string
  default     = "Canada Central"
}

variable "google_api_key" {
  description = "Google Places API key for the Flask app."
  type        = string
  sensitive   = true
  default     = "AIzaSyDMOv3ucij8PQPtVLPvFZ88arhaRfl0lEA"
}

variable "secret_key" {
  description = "Flask SECRET_KEY for session security."
  type        = string
  sensitive   = true
  default     = "aftabs_secret_key"
}

variable "jwt_secret_key" {
  description = "JWT secret key for authentication."
  type        = string
  sensitive   = true
  default     = "aftabs_jwt_secret_key"
}

variable "flask_app" {
  description = "Flask app entry point."
  type        = string
  default     = "manage.py"
}

variable "vm_admin_password" {
  description = "Admin password for the Azure VM."
  type        = string
  sensitive   = true
  default     = "SenecaCAA100"
} 