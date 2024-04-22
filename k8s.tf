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

resource "kubernetes_service" "flask" {
  metadata {
    namespace = kubernetes_namespace.staging.metadata[0].name
    name      = "flask-app-service"
  }

  spec {
    selector = {
      run = "flask"
    }

    session_affinity = "ClientIP"

    port {
      protocol    = "TCP"
      port        = 5000
      target_port = 5000
    }

    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.default.address
  }
}

resource "kubernetes_replication_controller" "flask" {
  metadata {
    name      = "flask-app-service"
    namespace = kubernetes_namespace.staging.metadata[0].name

    labels = {
      run = "flask"
    }
  }

  spec {
    selector = {
      run = "flask"
    }

    template {
      container {
        image = "kwongwaichun/project:latest"
        name  = "website-project"

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

output "load-balancer-ip" {
  value = google_compute_address.default.address
}