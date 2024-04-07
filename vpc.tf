variable "VpcCIDR" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "PublicSubnet1CIDR" {
  description = "CIDR block for the public subnet 1"
  default     = "10.0.1.0/24"
}

variable "PublicSubnet2CIDR" {
  description = "CIDR block for the public subnet 2"
  default     = "10.0.2.0/24"
}

variable "PrivateSubnet1CIDR" {
  description = "CIDR block for the private subnet 1"
  default     = "10.0.4.0/22"
}

variable "PrivateSubnet2CIDR" {
  description = "CIDR block for the private subnet 2"
  default     = "10.0.8.0/22"
}

resource "aws_vpc" "VPC" {
  cidr_block           = var.VpcCIDR
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Terraform-VPC"
  }
}

resource "aws_subnet" "PublicSubnet1" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = var.PublicSubnet1CIDR
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "PublicSubnet2" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = var.PublicSubnet2CIDR
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet2"
  }
}

resource "aws_subnet" "PrivateSubnet1" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = var.PrivateSubnet1CIDR
  availability_zone       = "us-east-1a"

  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "PrivateSubnet2" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = var.PrivateSubnet2CIDR
  availability_zone       = "us-east-1b"

  tags = {
    Name = "PrivateSubnet2"
  }
}

resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "InternetGateway"
  }
}

resource "aws_vpc_endpoint" "S3Endpoint" {
  vpc_id         = aws_vpc.VPC.id
  service_name   = "com.amazonaws.us-east-1.s3"
  route_table_ids = [aws_route_table.PrivateRouteTable1.id, aws_route_table.PrivateRouteTable2.id]
}

resource "aws_vpc_gateway_attachment" "InternetGatewayAttachment1" {
  vpc_id             = aws_vpc.VPC.id
  internet_gateway_id = aws_internet_gateway.InternetGateway.id
}

resource "aws_route_table" "PublicRouteTable1" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "PublicRouteTable1"
  }
}

resource "aws_route_table" "PublicRouteTable2" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "PublicRouteTable2"
  }
}

resource "aws_route_table" "PrivateRouteTable1" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "PrivateRouteTable1"
  }
}

resource "aws_route_table" "PrivateRouteTable2" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "PrivateRouteTable2"
  }
}

resource "aws_subnet_route_table_association" "PublicSubnet1RouteTableAssociation" {
  subnet_id      = aws_subnet.PublicSubnet1.id
  route_table_id = aws_route_table.PublicRouteTable1.id
}

resource "aws_subnet_route_table_association" "PublicSubnet2RouteTableAssociation" {
  subnet_id      = aws_subnet.PublicSubnet2.id
  route_table_id = aws_route_table.PublicRouteTable2.id
}

resource "aws_subnetThe rest of the Terraform code is missing in your question. However, I can provide you with the partial translation of the CloudFormation template to Terraform code. Please note that you might need to complete the remaining resources and make adjustments based on your specific requirements:

```hcl
resource "aws_subnet_route_table_association" "PrivateSubnet1RouteTableAssociation" {
  subnet_id      = aws_subnet.PrivateSubnet1.id
  route_table_id = aws_route_table.PrivateRouteTable1.id
}

resource "aws_subnet_route_table_association" "PrivateSubnet2RouteTableAssociation" {
  subnet_id      = aws_subnet.PrivateSubnet2.id
  route_table_id = aws_route_table.PrivateRouteTable2.id
}

resource "aws_route" "PublicRouteTable1DefaultRoute" {
  route_table_id            = aws_route_table.PublicRouteTable1.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.InternetGateway.id
}

resource "aws_route" "PublicRouteTable2DefaultRoute" {
  route_table_id            = aws_route_table.PublicRouteTable2.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.InternetGateway.id
}