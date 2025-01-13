terraform {
  required_version = ">=0.13.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.48, < 6"
    }

    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}
