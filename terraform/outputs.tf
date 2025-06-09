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