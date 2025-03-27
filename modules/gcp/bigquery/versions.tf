terraform {
  required_version = ">=1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=6.27.0"
    }
  }
}
