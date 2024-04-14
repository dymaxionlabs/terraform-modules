output "workload_identity_provider" {
  description = "The ID of the workload identity provider"
  value       = google_iam_workload_identity_pool_provider.default.name
}

output "service_account" {
  description = "The email of the GitHub Actions service account"
  value       = google_service_account.default.email
}
