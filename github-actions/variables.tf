variable "project" {
  description = "The project id where the GitHub Actions service account will be created"
  type        = string
}

variable "owner" {
  description = "The owner of the GitHub repositories"
  type        = string
}

variable "repositories" {
  description = "A list of GitHub repositories to grant access to the GitHub Actions service account"
  type        = list(string)
}

variable "service_account_id" {
  description = "The id of the GitHub Actions service account"
  type        = string
  default     = "github-actions"
}

variable "service_account_roles" {
  description = "A list of roles to grant to the GitHub Actions service account"
  type        = list(string)
  default     = []
}
