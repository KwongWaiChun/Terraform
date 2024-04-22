variable "project_id" {
  description = "Project ID of the GCP project"
}

variable "region" {
  description = "Region for the GCP resources"
}

variable "zone" {
  description = "Zone for the GCP resources"
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
}

variable "node_pool_name" {
  description = "Name of the Kubernetes node pool"
}

variable "num_nodes" {
  description = "Number of nodes in the Kubernetes node pool"
}

variable "docker_image" {
  description = "Docker image to use for the Kubernetes deployment"
}

variable "docker_tag" {
  description = "Docker tag to use for the Kubernetes deployment"
}