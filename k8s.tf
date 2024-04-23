provider "kubernetes" {
  version = "~> 1.10.0"
  host    = google_container_cluster.default.endpoint
  token   = data.google_client_config.current.access_token
  client_certificate = base64decode(
    google_container_cluster.default.master_auth[0].client_certificate,
  )
  client_key = base64decode(google_container_cluster.default.master_auth[0].client_key)
  cluster_ca_certificate = base64decode(
    google_container_cluster.default.master_auth[0].cluster_ca_certificate,
  )
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
  }
}

resource "google_compute_address" "default" {
  name   = var.network_name
  region = var.region
}

resource "kubernetes_service" "nginx" {
  metadata {
    namespace = kubernetes_namespace.staging.metadata[0].name
    name      = "nginx"
  }

  spec {
    selector = {
      run = "nginx"
    }

    session_affinity = "ClientIP"

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.default.address
  }
}

resource "kubernetes_replication_controller" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.staging.metadata[0].name

    labels = {
      run = "nginx"
    }
  }

  spec {
    selector = {
      run = "nginx"
    }

    template {
      container {
        image = "kwongwaichun/fyp:latest"
        name  = "nginx"

        resources {
          limits {
            cpu    = "0.5"
            memory = "512Mi"
          }

          requests {
            cpu    = "250m"
            memory = "50Mi"
          }
        }
      }
    }
  }
}

resource "google_container_node_pool" "default" {
  name       = "default-node-pool"
  location   = var.region
  cluster    = google_container_cluster.default.name
  node_count = 3

  autoscaling {
    min_node_count = 3
    max_node_count = 5
  }

  node_config {
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

output "load-balancer-ip" {
  value = google_compute_address.default.address
}