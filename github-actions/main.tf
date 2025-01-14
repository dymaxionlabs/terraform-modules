provider "github" {
  owner = var.owner
}

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
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }
  # attribute_condition = join(" || ", [
  #   for repo in var.repositories : "attribute.repository == \"${var.owner}/${repo}\""
  # ])
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

resource "github_actions_variable" "project_id" {
  for_each = toset(var.repositories)

  repository    = each.key
  variable_name = "GCP_PROJECT_ID"
  value         = var.project
}

resource "github_actions_variable" "workload_identity_provider" {
  for_each = toset(var.repositories)

  repository    = each.key
  variable_name = "GCP_WORKLOAD_IDENTITY_PROVIDER"
  value         = google_iam_workload_identity_pool_provider.default.name
}

resource "github_actions_variable" "service_account" {
  for_each = toset(var.repositories)

  repository    = each.key
  variable_name = "GCP_SERVICE_ACCOUNT"
  value         = google_service_account.default.email
}
