resource "google_iam_workload_identity_pool" "default" {
  project                   = var.project
  workload_identity_pool_id = "github"
}

resource "google_iam_workload_identity_pool_provider" "default" {
  project                            = var.project
  workload_identity_pool_id          = google_iam_workload_identity_pool.default.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "default" {
  project      = var.project
  account_id   = var.service_account_id
  display_name = "GitHub Actions"
}

resource "google_service_account_iam_member" "default" {
  for_each = toset(var.repositories)

  service_account_id = google_service_account.default.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.default.name}/attribute.repository/${each.value}"
}

resource "google_project_iam_member" "default" {
  for_each = toset(var.service_account_roles)

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.default.email}"
}
