variable "region" {
  default = "asia-east1" // Set as per your nearest location or preference 
}

variable "location" {
  default = "asia-east1-b"  // Set as per your nearest location or preference 
}

variable "network_name" {
  default = "tf-gke-k8s"
}

provider "google" {
  region = var.region
}

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = var.network_name
  ip_cidr_range            = "10.140.0.0/20"  // Change as per your region/zone
  network                  = google_compute_network.default.self_link
  region                   = var.region
  private_ip_google_access = true
}

resource "google_service_networking_connection" "vpc_peering" {
  provider = google-beta
  network                 = google_compute_network.default.name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges =       [google_compute_global_address.peering_address.name]
}

resource "google_compute_global_address" "flask_app_ip" {
  name = "flask-app-ip"
}

data "google_client_config" "current" {
}

data "google_container_engine_versions" "default" {
  location = var.location
}

resource "google_container_cluster" "default" {
  name               = var.network_name
  location           = var.location
  initial_node_count = 3
  min_master_version = data.google_container_engine_versions.default.latest_master_version
  network            = google_compute_subnetwork.default.name
  subnetwork         = google_compute_subnetwork.default.name

  remove_default_node_pool = true
  enable_legacy_abac = true

  // Wait for the GCE LB controller to cleanup the resources.
  // Wait for the GCE LB controller to cleanup the resources.
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 90"
  }

  provider = google-beta
  
  cluster_autoscaling {
    enabled = true
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
    resource_limits {
      resource_type = "cpu"
      minimum = 2
      maximum = 8
    }
    resource_limits {
      resource_type = "memory"
      minimum = 8
      maximum = 16
    }
  }

  vertical_pod_autoscaling {
    enabled = true
  }
}


output "network" {
  value = google_compute_subnetwork.default.network
}

output "subnetwork_name" {
  value = google_compute_subnetwork.default.name
}

output "cluster_name" {
  value = google_container_cluster.default.name
}

output "cluster_region" {
  value = var.region
}

output "cluster_location" {
  value = google_container_cluster.default.location
}