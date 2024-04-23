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

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
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
}

resource "kubernetes_horizontal_pod_autoscaler" "nginx" {
  metadata {
    name      = "nginx-autoscaler"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }

  spec {
    scale_target_ref {
      name       = kubernetes_replication_controller.nginx.metadata[0].name
      api_version = "apps/v1"
      kind       = "ReplicationController"
    }

    min_replicas = 1
    max_replicas = 10

    metrics {
      type = "Resource"

      resource {
        name = "cpu"
        target_average_utilization = 50
      }
    }
  }
}
output "load-balancer-ip" {
  value = google_compute_address.default.address
}