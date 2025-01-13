# github-actions

This module helps configure GitHub Actions workflows in a GCP project.

It follows the requirements for the [Workload Identity Federation through a
Service
Account](https://github.com/google-github-actions/auth?tab=readme-ov-file#workload-identity-federation-through-a-service-account)
method, as instructed by the
[google-github-actions/auth](https://github.com/google-github-actions/auth)
GitHub Action.

This [gist](https://gist.github.com/palewire/12c4b2b974ef735d22da7493cf7f4d37)
was also used as a reference.

## Usage

```hcl
module "github_actions" {
  source = "github.com/dymaxionlabs/terraform-modules//github-actions"

  project      = var.project_id
  owner        = var.github_organization
  repositories = [
    "dymaxionlabs/optimus-app"
  ]
  service_account_roles = [
    "roles/artifactregistry.writer",
    "roles/secretmanager.secretAccessor"
  ]  
}
```

In this example, the service account used will have the roles
`roles/artifactregistry.writer` and `roles/secretmanager.secretAccessor`, which
allows Github to pull/push to an artifact registry, and access secrets in the
project.  Adjust the service account roles according to your needs.

The module automatically sets the following repository variables, to configure
Github Actions correctly:

* `GCP_PROJECT_ID`: The project ID
* `GCP_SERVICE_ACCOUNT`: The email of the service account created
* `GCP_WORKLOAD_IDENTITY_PROVIDER`: The ID of the workload identity provider

You can also these as outputs, in case you need them for other purposes:

```hcl
output "github_actions_workload_provider" {
  description = "The ID of the GitHub Actions workload identity provider"
  value       = module.github_actions.workload_identity_provider
}

output "github_actions_service_account" {
  description = "The email of the GitHub Actions service account"
  value       = module.github_actions.service_account
}
```

### Example on Github Actions

Use this step at the beginning of your GitHub Actions workflow to authenticate with Google Cloud:

```yaml
- id: auth
  name: Authenticate with Google Cloud
  uses: google-github-actions/auth@v2
  with:
    token_format: access_token
    workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
    service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```
