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

resource "kubernetes_ingress" "k8s-ingress" {
  metadata {
    name      = "k8s-ingress"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  
  spec {
    rule {
      host = "fyp-project.com"
      http {
        path {
          backend {
            service_name = kubernetes_service.nginx.metadata[0].name
            service_port = 8080
          }
          path = "/"
        }
      }
    }
    
    tls {
      hosts      = ["fyp-project.com"]
      secret_name = kubernetes_secret.tls_cred.metadata[0].name
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "flask-hpa" {
  metadata {
    name = "flask-hpa"
  }

  spec {
    max_replicas = 4
    min_replicas = 1

    scale_target_ref {
      kind = "Deployment"
      name = "nginx"
    }
    target_cpu_utilization_percentage = 75
  }
}

output "load-balancer-ip" {
  value = google_compute_address.default.address
}