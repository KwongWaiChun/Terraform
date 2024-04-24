terraform {
  backend "gcs" {}
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.10.0"
    }
  }
}