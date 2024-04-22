# https://www.terraform.io/language/settings/backends/gcs
terraform {
  backend "gcs" {}
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs
provider "google" {
  region  = "us-central1"
}
