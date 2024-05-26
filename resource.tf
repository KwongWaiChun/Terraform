resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Terraform-VPC"
  }
}

resource "aws_subnet" "public_subnet1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet1_cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet2_cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "PublicSubnet2"
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.private_subnet1_cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.private_subnet2_cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "PrivateSubnet2"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "InternetGateway"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  service_name = "com.amazonaws.us-east-1.s3"
  vpc_id = aws_vpc.vpc.id
  route_table_ids = [
    aws_route_table.private_route_table1.id,
    aws_route_table.private_route_table2.id
  ]
}

resource "aws_route_table" "public_route_table1" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "PublicRouteTable1"
  }
}

resource "aws_route_table" "public_route_table2" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "PublicRouteTable2"
  }
}

resource "aws_route_table" "private_route_table1" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "PrivateRouteTable1"
  }
}

resource "aws_route_table" "private_route_table2" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "PrivateRouteTable2"
  }
}

resource "aws_route_table_association" "public_subnet1_route_table_association" {
  subnet_id = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table1.id
}

resource "aws_route_table_association" "public_subnet2_route_table_association" {
  subnet_id = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_route_table2.id
}

resource "aws_route_table_association" "private_subnet1_route_table_association" {
  subnet_id = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table1.id
}

resource "aws_route_table_association" "private_subnet2_route_table_association" {
  subnet_id = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_route_table2.id
}

resource "aws_route" "public_route_table1_default_route" {
  route_table_id = aws_route_table.public_route_table1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
}

resource "aws_route" "public_route_table2_default_route" {
  route_table_id = aws_route_table.public_route_table2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
}

resource "aws_security_group" "aurora_security_group" {
  description = "Aurora security group"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "aurora_security_group_ingress" {
  security_group_id = aws_security_group.aurora_security_group.id
  ip_protocol = "tcp"
  from_port = 3306
  to_port = 3306
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "auroradb-subnetgroup"
  description = "Subnet group for Aurora DB"
  subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
}

resource "aws_security_group" "ec2_security_group" {
  description = "bastion host security group"
  name = "BastionHostSecurityGroup"
  vpc_id = aws_vpc.vpc.id
  ingress {
      cidr_blocks = ["0.0.0.0/0"]
      protocol = "tcp"
      from_port = 22
      to_port = 22
    }
  egress {
      cidr_blocks = ["0.0.0.0/0"]
      protocol = "-1"
      from_port = 0
      to_port = 0
    }
}

resource "tls_private_key" "ec2_tls_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
 }

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2-key"
  public_key = tls_private_key.ec2_tls_key.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.ec2_key_pair.key_name}.pem"
  content = tls_private_key.ec2_tls_key.private_key_pem
}

resource "aws_s3_bucket" "key_bucket" {
  bucket_prefix = "key-bucket"
}

resource "aws_s3_object" "ssh_key" {
  bucket = aws_s3_bucket.key_bucket.id
  key = "${aws_key_pair.ec2_key_pair.key_name}.pem"
  source = local_file.ssh_key.filename
}

resource "aws_eip" "ec2_instance1_eip" {
  domain = "vpc"
}

resource "aws_eip_association" "ec2_instance1_eip_association" {
  instance_id = aws_instance.ec2_instance1.id
  allocation_id = aws_eip.ec2_instance1_eip.id
}

resource "aws_instance" "ec2_instance1" {
  ami = "ami-06b09bfacae1453cb"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2_key_pair.key_name

  associate_public_ip_address = false
  subnet_id = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    delete_on_termination = true
    encrypted   = false
  }

  tags = {
    "Name" = "BastionHost1"
  }
}

resource "aws_eip" "ec2_instance2_eip" {
  domain = "vpc"
}

resource "aws_eip_association" "ec2_instance2_eip_association" {
  instance_id = aws_instance.ec2_instance2.id
  allocation_id = aws_eip.ec2_instance2_eip.id
}

resource "aws_instance" "ec2_instance2" {
  ami = "ami-06b09bfacae1453cb"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2_key_pair.key_name

  associate_public_ip_address = false
  subnet_id = aws_subnet.public_subnet2.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    delete_on_termination = true
    encrypted   = false
  }

  tags = {
    "Name" = "BastionHost2"
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = "aurora-cluster-instance"
  availability_zones = ["us-east-1a", "us-east-1b"]
  engine = "aurora-postgresql"
  engine_mode = "provisioned"
  engine_version = "16.1"
  database_name = var.database_name
  enable_http_endpoint = true
  master_username = var.master_username
  master_password = var.master_password
  backup_retention_period = 7
  preferred_backup_window = "02:00-04:00"
  skip_final_snapshot = true
  storage_encrypted  = true
  serverlessv2_scaling_configuration {
    max_capacity = 8
    min_capacity = 0.5
  }
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.aurora_security_group.id]
}

resource "aws_rds_cluster_instance" "aurora_cluster_instance" {
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version
}

resource "aws_s3_bucket" "snapshot_bucket" {
  bucket_prefix = "snapshot-bucket"
}

