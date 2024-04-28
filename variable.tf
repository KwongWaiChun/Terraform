variable vpc_cidr {
  description = "CIDR block for the VPC"
  type = string
  default = "10.0.0.0/16"
}

variable public_subnet1_cidr {
  description = "CIDR block for the public subnet 1"
  type = string
  default = "10.0.1.0/24"
}

variable public_subnet2_cidr {
  description = "CIDR block for the public subnet 2"
  type = string
  default = "10.0.2.0/24"
}

variable private_subnet1_cidr {
  description = "CIDR block for the private subnet 1"
  type = string
  default = "10.0.4.0/22"
}

variable private_subnet2_cidr {
  description = "CIDR block for the private subnet 2"
  type = string
  default = "10.0.8.0/22"
}

