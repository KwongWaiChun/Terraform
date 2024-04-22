variable "cluster" {
  default = "terraform-workshops"
}
variable "app" {
  type        = string
  description = "Name of application"
  default     = "k8s-website"
}
variable "zone" {
  default = "us-east1-b"
}
variable "docker-image" {
  type        = string
  description = "name of the docker image to deploy"
  default     = "kwongwaichun/project:latest"
}