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
      port        = 8080
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
        run = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          run = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "kwongwaichun/fyp:latest"

          resources {
            limits {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          # Add the following configurations to enable logging
          env {
            name = "GOOGLE_CLOUD_PROJECT"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name = "GOOGLE_CLOUD_LOCATION"
            value = "us-central1"
          }

          env {
            name = "GOOGLE_CLOUD_LOGGING_DESTINATION"
            value = google_logging_project_sink.default.name
          }

          env {
            name = "GOOGLE_CLOUD_LOGGING_ONLY_ERRORS"
            value = "false"
          }

          env {
            name = "GOOGLE_CLOUD_LOGGING_ONLY_WARNINGS"
            value = "false"
          }

          env {
            name = "GOOGLE_CLOUD_LOGGING_ONLY_CRITICAL"
            value = "false"
          }

          env {
            name = "GOOGLE_CLOUD_LOGGING_ONLY_INFO"
            value = "true"
          }

          env {
            name = "GOOGLE_CLOUD_LOGGING_ONLY_DEBUG"
            value = "false"
          }
        }
      }
    }
  }
}

resource "kubernetes_secret" "tls_cred" {
  metadata {
            name = "tls-cred"
            namespace = kubernetes_namespace.staging.metadata[0].name
          }
  data = {
            "tls.crt" = file("tls.crt")
            "tls.key" = file("tls.key")
        }
type = "kubernetes.io/tls"
}

output "load-balancer-ip" {
  value = google_compute_address.default.address
}