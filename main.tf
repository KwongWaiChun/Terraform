

# Create a VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "my-vpc-network"
  auto_create_subnetworks = false
}

# Create a subnet within the VPC
resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  network       = google_compute_network.vpc_network.self_link
  ip_cidr_range = "10.0.0.0/24"

  region                     = "us-central1"
  private_ip_google_access   = true
  secondary_ip_range {
    range_name    = "my-secondary-range"
    ip_cidr_range = "10.0.1.0/24"
  }
}

# Create a GKE cluster
resource "google_container_cluster" "gke_cluster" {
  name               = "my-gke-cluster"
  location           = "us-central1"
  remove_default_node_pool = true

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  initial_node_count = 1

  node_pool {
    name         = "default-pool"
    machine_type = "n1-standard-2"
    disk_size_gb = 100
    node_count   = 1
    autoscaling {
      min_node_count = 1
      max_node_count = 5
    }
    management {
      auto_repair  = true
      auto_upgrade = true
    }
  }

  network_config {
    subnetwork = google_compute_subnetwork.subnet.self_link
    ip_allocation_policy {
      cluster_secondary_range_name = google_compute_subnetwork.subnet.secondary_ip_range.0.range_name
    }
  }
}

# Create a regional GKE node pool
resource "google_container_node_pool" "regional_node_pool" {
  name       = "regional-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.gke_cluster.name
  node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Create a regional forwarding rule for load balancing
resource "google_compute_forwarding_rule" "lb_forwarding_rule" {
  name             = "lb-forwarding-rule"
  region           = "us-central1"
  ip_protocol      = "TCP"
  port_range       = "80-8080"
  target           = google_container_node_pool.regional_node_pool.self_link
  load_balancing_scheme = "EXTERNAL"
}

# Create a health check for load balancing
resource "google_compute_health_check" "lb_health_check" {
  name                = "lb-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  tcp_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

# Attach the health check to the load balancer
resource "google_compute_backend_service" "lb_backend_service" {
  name            = "lb-backend-service"
  health_checks   = [google_compute_health_check.lb_health_check.self_link]
  backend {
    group = google_container_node_pool.regional_node_pool.instance_group_urls[0]
  }
}

# Create a URL map for load balancing
resource "google_compute_url_map" "lb_url_map" {
  name             = "lb-url-map"
  default_service  = google_compute_backend_service.lb_backend_service.self_link
}

# Create a target HTTP proxy for load balancing
resource "google_compute_target_http_proxy" "lb_target_http_proxy" {
  name    = "lb-target-http-proxy"
  url_map = google_compute_url_map.lb_url_map.self_link
}

# Create a global forwarding rule for load balancing
resource "google_compute_global_forwarding_rule" "lb_global_forwarding_rule" {
  name        = "lb-global-forwarding-rule"
  target      = google_compute_target_http_proxy.lb_target_http_proxy.self_link
  port_range  = "80-8080"
}