# opsbase: AWX on GCP with Terraform Cloud

## ✪ Overview

**opsbase** is an Infrastructure-as-Code (IaC) project to deploy **AWX** (the open-source web UI for Ansible) on **Google Cloud Platform (GCP)** using **Terraform Cloud** and **Cloud Run**. It is optimized for:

- Minimal cost using Cloud Run's auto-scaling and zero-cost idle state
- Declarative provisioning of infrastructure
- GitHub Actions CI/CD integration
- Terraform Cloud workspace as a central control point

---

## 🏠 Directory Structure

```text
opsbase/
├── terraform/                      # Terraform IaC modules
│   ├── main.tf                    # Defines GCP resources
│   ├── variables.tf              # Input variable definitions
│   ├── outputs.tf                # Terraform output values
│   └── terraform.tfvars          # Example variable values
├── docker/                        # Docker build for AWX
│   ├── Dockerfile                # Custom AWX container
│   └── install_awx.sh            # Initialization script
└── .github/
    └── workflows/
        └── deploy.yml            # GitHub Actions CI/CD (optional)
```

---

## 🚀 Deployment Steps (Terraform Cloud + GCP)

### 1. Prerequisites
- GCP project with billing and required APIs enabled: 
  - Artifact Registry
  - Cloud Run
  - Cloud SQL Admin
  - IAM & Admin
- Terraform Cloud account and a workspace (linked to this repo)
- GitHub repository for storing this project
- `gcloud` CLI and Docker installed locally

### 2. Build and Push AWX Docker Image
```bash
gcloud auth configure-docker asia-northeast1-docker.pkg.dev

docker build -t asia-northeast1-docker.pkg.dev/YOUR_PROJECT_ID/awx-repo/awx ./docker
docker push asia-northeast1-docker.pkg.dev/YOUR_PROJECT_ID/awx-repo/awx
```

### 3. Set Up Terraform Cloud Workspace
1. Go to Terraform Cloud → Create Workspace
2. Choose **Version Control Workflow** and link this GitHub repository
3. Set working directory to `terraform/`
4. Add the following variables under the **Variables** tab:

| Name | Value | Type |
|------|-------|------|
| `TF_VAR_project_id` | your-gcp-project-id | Environment |
| `TF_VAR_region` | asia-northeast1 | Environment |
| `TF_VAR_awx_image` | asia-northeast1-docker.pkg.dev/... | Environment |
| `TF_VAR_database_url` | postgres://awxuser:password@... | Environment |
| `TF_VAR_db_user` | awxuser | Environment |
| `TF_VAR_db_password` | yourpassword | Environment (Sensitive) |
| `TF_VAR_db_name` | awxdb | Environment |

> ✅ Sensitive values like `db_password` should be marked as **sensitive**.

### 4. Trigger a Plan and Apply
1. Click **Queue Plan** in your Terraform Cloud workspace
2. Review the plan
3. Click **Confirm & Apply**

### 5. Access the AWX Web UI
Once the apply finishes, you can access AWX via:
```bash
terraform output awx_url
```
Open that URL in your browser.

---

## terraform/main.tf

```hcl
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
```

---

## terraform/variables.tf

```hcl
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
```

---

## terraform/outputs.tf

```hcl
output "awx_url" {
  description = "The URL to access AWX in Cloud Run."
  value       = google_cloud_run_service.awx.status[0].url
}

output "sql_instance_name" {
  description = "Cloud SQL instance name."
  value       = google_sql_database_instance.awx.name
}

output "sql_database_name" {
  description = "Database name in Cloud SQL."
  value       = google_sql_database.awx.name
}
```

---

## terraform/terraform.tfvars (example)

```hcl
project_id   = "your-gcp-project-id"
region       = "asia-northeast1"

awx_image    = "asia-northeast1-docker.pkg.dev/your-gcp-project-id/awx-repo/awx"
database_url = "postgres://awxuser:yourpassword@/cloudsql/your-connection-string"

db_user      = "awxuser"
db_password  = "yourpassword"
db_name      = "awxdb"
```

> 💡 Tip: Keep your secrets (like `db_password`) stored securely using Terraform Cloud variable sets or environment variables with `sensitive` flag.

---

## docker/Dockerfile

```Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y git curl python3 python3-pip gnupg2 nginx postgresql-client && \
    pip3 install ansible

# Install Docker-compose AWX dependencies
RUN pip3 install docker-compose

# Clone and install AWX from source
RUN git clone -b 21.14.0 https://github.com/ansible/awx.git /awx
WORKDIR /awx/installer

COPY install_awx.sh /install_awx.sh
RUN chmod +x /install_awx.sh

CMD ["/install_awx.sh"]
```

> ℹ️ This Dockerfile builds an AWX container suitable for running on Cloud Run. It installs the required packages and sets up the AWX environment using an included script.

---

## 💸 Cost Optimization

- **Cloud Run**: scales to 0 on idle, no runtime cost
- **Cloud SQL**: can be destroyed or stopped when not in use
- **Artifact Registry**: free up to 1 GB/month

> Estimated monthly cost: ¥700 - ¥1,000 when active / under ¥100 when idle

---

## 📚 Resources

- [AWX GitHub](https://github.com/ansible/awx)
- [Terraform Cloud Docs](https://developer.hashicorp.com/terraform/cloud-docs)
- [Cloud Run Docs](https://cloud.google.com/run/docs)

---

## 📨 Feedback

Feel free to open an issue or submit a pull request for suggestions and improvements.
