terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.3.0"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
  
  backend "gcs" {}
}

provider "google" {
  # Configuration options
}

provider "kubernetes" {
  # Configuration options
}