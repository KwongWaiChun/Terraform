# https://www.terraform.io/language/settings/backends/gcs
terraform {
  backend "gcs" {}
}

terraform {
  required_version = ">= 0.12"
}