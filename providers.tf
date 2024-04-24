# https://www.terraform.io/language/settings/backends/gcs
terraform {
  backend "gcs" {}
}

terraform {
 required_providers {
   google = {
     source = "hashicorp/google"
     version = "5.3.0"
   }
 }
}

provider "google" {
 # Configuration options
}

terraform {
 required_providers {
   kubernetes = {
     source = "hashicorp/kubernetes"
     version = "2.23.0"
   }
 }
}

provider "kubernetes" {
 # Configuration options
}