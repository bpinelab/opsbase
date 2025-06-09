variable "project_id" {
  description = "The GCP project ID where resources will be deployed"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources (e.g., asia-northeast1)"
  type        = string
  default     = "asia-northeast1"
}

variable "db_password" {
  description = "The password for the Cloud SQL PostgreSQL user"
  type        = string
  sensitive   = true
}
