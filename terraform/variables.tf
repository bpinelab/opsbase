variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources in."
  type        = string
  default     = "asia-northeast1"
}

variable "awx_image" {
  description = "Full container image path for AWX."
  type        = string
}

variable "database_url" {
  description = "Database URL for AWX environment."
  type        = string
}

variable "db_user" {
  description = "Username for PostgreSQL database."
  type        = string
}

variable "db_password" {
  description = "Password for PostgreSQL user."
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the AWX PostgreSQL database."
  type        = string
}