terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "awx" {
  repository_id = "awx-repo"
  format        = "DOCKER"
  location      = var.region
}

resource "google_cloud_run_service" "awx" {
  name     = "awx"
  location = var.region

  template {
    spec {
      containers {
        image = var.awx_image
        ports {
          container_port = 8052
        }
        env {
          name  = "DATABASE_URL"
          value = var.database_url
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

resource "google_sql_database_instance" "awx" {
  name             = "awx-sql"
  region           = var.region
  database_version = "POSTGRES_13"

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_user" "awx" {
  name     = var.db_user
  instance = google_sql_database_instance.awx.name
  password = var.db_password
}

resource "google_sql_database" "awx" {
  name     = var.db_name
  instance = google_sql_database_instance.awx.name
}