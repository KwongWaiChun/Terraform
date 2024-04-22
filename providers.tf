# https://www.terraform.io/language/settings/backends/gcs
terraform {
  backend "gcs" {}
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.0.0"
    }
  }
}