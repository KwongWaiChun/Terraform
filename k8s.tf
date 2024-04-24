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

resource "tls_private_key" "nginx" {
  algorithm = "RSA"
}

resource "tls_locally_signed_cert" "nginx" {
  locals {
    common_name = "k8s.tf"
  }

  cert_request {
    private_key_pem = tls_private_key.nginx.private_key_pem

    dns_names = [
      "k8s.tf",
    ]
  }

  validity_period_hours = 12
}

resource "kubernetes_secret" "tls" {
  metadata {
    name      = "tls-secret"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }

  data = {
    "tls.crt" = tls_locally_signed_cert.nginx.cert_pem
    "tls.key" = tls_private_key.nginx.private_key_pem
  }

  type = "kubernetes.io/tls"
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
      port        = 443
      target_port = 80
    }

    type = "LoadBalancer"
    load_balancer_ip = google_compute_address.default.address
  }
}

resource "kubernetes_ingress" "nginx" {
  metadata {
    namespace = kubernetes_namespace.staging.metadata[0].name
    name      = "nginx"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/ssl-passthrough" = "true"
    }
  }

  spec {
    tls {
      hosts = [
        "k8s.tf",
      ]
      secret_name = kubernetes_secret.tls.metadata[0].name
    }

    rule {
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.nginx.metadata[0].name
              port {
                number = 443
              }
            }
          }
        }
      }
    }
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
        }
      }
    }
  }
}

output "load-balancer-ip" {
  value = google_compute_address.default.address
}