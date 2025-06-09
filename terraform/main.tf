provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "awx" {
  provider   = google
  location   = var.region
  repository_id = "awx-repo"
  description   = "AWX Docker repository"
  format        = "DOCKER"
}

resource "google_cloud_run_service" "awx" {
  name     = "awx-service"
  location = var.region

  template {
    spec {
      containers {
        image = "asia-northeast1-docker.pkg.dev/${var.project_id}/awx-repo/awx:latest"
        ports {
          container_port = 8052
        }
      }
    }
  }

  traffics {
    percent         = 100
    latest_revision = true
  }
}

resource "google_sql_database_instance" "awx" {
  name             = "awx-sql"
  region           = var.region
  database_version = "POSTGRES_13"

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = true
    }
  }
}

resource "google_sql_database" "awx" {
  name     = "awx"
  instance = google_sql_database_instance.awx.name
}

resource "google_sql_user" "awx" {
  name     = "awxuser"
  instance = google_sql_database_instance.awx.name
  password = var.db_password
}

output "cloud_run_url" {
  value = google_cloud_run_service.awx.status[0].url
}
