terraform {
  required_version = ">=0.13.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0, < 7.0.0"
    }

    github = {
      source  = "integrations/github"
      version = "~> 6.4.0"
    }
  }
}
