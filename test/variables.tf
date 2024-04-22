variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "zone" {
  type        = string
  description = "GCP Zone"
}

variable "cluster_name" {
  type        = string
  description = "Kubernetes Cluster Name"
}

variable "node_pool_name" {
  type        = string
  description = "Kubernetes Node Pool Name"
}

variable "min_nodes" {
  type        = number
  description = "Minimum number of nodes in the Node Pool"
}

variable "max_nodes" {
  type        = number
  description = "Maximum number of nodes in the Node Pool"
}

variable "image_name" {
  type        = string
  description = "Docker Hub Image Name"
}

variable "image_tag" {
  type        = string
  description = "Docker Hub Image Tag"
}

variable "container_port" {
  type        = number
  description = "Container Port"
}

variable "tls_secret_name" {
  type        = string
  description = "Kubernetes Secret Name for SSL/TLS"
}