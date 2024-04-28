resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Terraform-VPC"
  }
}

resource "aws_subnet" "public_subnet1" {
  vpc_id = aws_vpc.vpc.arn
  cidr_block = var.public_subnet1_cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id = aws_vpc.vpc.arn
  cidr_block = var.public_subnet2_cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "PublicSubnet2"
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id = aws_vpc.vpc.arn
  cidr_block = var.private_subnet1_cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id = aws_vpc.vpc.arn
  cidr_block = var.private_subnet2_cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "PrivateSubnet2"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  tags = {
    Name = "InternetGateway"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  service_name = "com.amazonaws.us-east-1.s3"
  vpc_id = aws_vpc.vpc.arn
  route_table_ids = [
    aws_route_table.private_route_table1.id,
    aws_route_table.private_route_table2.id
  ]
}

resource "aws_vpn_gateway_attachment" "internet_gateway_attachment1" {
  vpc_id = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table" "public_route_table1" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "PublicRouteTable1"
  }
}

resource "aws_route_table" "public_route_table2" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "PublicRouteTable2"
  }
}

resource "aws_route_table" "private_route_table1" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "PrivateRouteTable1"
  }
}

resource "aws_route_table" "private_route_table2" {
  vpc_id = aws_vpc.vpc.arn
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
  vpc_id = aws_vpc.vpc.arn
}

resource "aws_vpc_security_group_ingress_rule" "aurora_security_group_ingress" {
  referenced_security_group_id = aws_security_group.aurora_security_group.arn
  ip_protocol = "tcp"
  from_port = 3306
  to_port = 3306
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "auroradb-SubnetGroup"
  description = "Subnet group for Aurora DB"
  subnet_ids = [
    aws_subnet.private_subnet1.id,
    aws_subnet.private_subnet2.id
  ]
}

resource "aws_security_group" "ec2_security_group" {
  description = "bastion host security group"
  name = "BastionHostSecurityGroup"
  vpc_id = aws_vpc.vpc.arn
  ingress = [
    {
      cidr_blocks = "0.0.0.0/0"
      from_port = 22
      protocol = "tcp"
      to_port = 22
    }
  ]
  egress = [
    {
      cidr_blocks = "0.0.0.0/0"
      protocol = -1
    }
  ]
}

resource "aws_ec2_fleet" "ec2_instance1_eip" {
  // CF Property(Domain) = "vpc"
}

resource "aws_eip_association" "ec2_instance1_eip_association" {
  instance_id = aws_ec2_instance_state.ec2_instance1.id
  // CF Property(EIP) = aws_ec2_fleet.ec2_instance1_eip.id
}

resource "aws_ec2_instance_state" "ec2_instance1" {
  // CF Property(ImageId) = "ami-06b09bfacae1453cb"
  instance_id = "t2.micro"
  // CF Property(NetworkInterfaces) = [
  //   {
  //     AssociatePublicIpAddress = false
  //     DeviceIndex = 0
  //     SubnetId = aws_subnet.public_subnet1.id
  //     DeleteOnTermination = true
  //     GroupSet = [
  //       aws_security_group.ec2_security_group.arn
  //     ]
  //   }
  // ]
  // CF Property(BlockDeviceMappings) = [
  //   {
  //     DeviceName = "/dev/xvda"
  //     Ebs = {
  //       Encrypted = false
  //       VolumeSize = 8
  //       SnapshotId = "snap-0ad2348eab4dde717"
  //       VolumeType = "gp3"
  //       DeleteOnTermination = true
  //     }
  //   }
  // ]
  // CF Property(tags) = {
  //   Name = "BastionHost1"
  // }
}

resource "aws_ec2_fleet" "ec2_instance2_eip" {
  // CF Property(Domain) = "vpc"
}

resource "aws_eip_association" "ec2_instance2_eip_association" {
  instance_id = aws_ec2_instance_state.ec2_instance2.id
  // CF Property(EIP) = aws_ec2_fleet.ec2_instance2_eip.id
}

resource "aws_ec2_instance_state" "ec2_instance2" {
  // CF Property(ImageId) = "ami-06b09bfacae1453cb"
  instance_id = "t2.micro"
  // CF Property(NetworkInterfaces) = [
  //   {
  //     AssociatePublicIpAddress = false
  //     DeviceIndex = 0
  //     SubnetId = aws_subnet.public_subnet2.id
  //     DeleteOnTermination = true
  //     GroupSet = [
  //       aws_security_group.ec2_security_group.arn
  //     ]
  //   }
  // ]
  // CF Property(BlockDeviceMappings) = [
  //   {
  //     DeviceName = "/dev/xvda"
  //     Ebs = {
  //       Encrypted = false
  //       VolumeSize = 8
  //       SnapshotId = "snap-0ad2348eab4dde717"
  //       VolumeType = "gp3"
  //       DeleteOnTermination = true
  //     }
  //   }
  // ]
  // CF Property(tags) = {
  //   Name = "BastionHost2"
  // }
}

resource "aws_rds_cluster" "aurora_cluster" {
  engine = "aurora-mysql"
  engine_mode = "serverless"
  engine_version = "5.7.mysql_aurora.2.07.1"
  database_name = "MyDatabase"
  master_username = "admin"
  manage_master_user_password = "admin123"
  enable_http_endpoint = true
  scaling_configuration = {
    AutoPause = true
    MaxCapacity = 16
    MinCapacity = 2
    SecondsUntilAutoPause = 300
    TimeoutAction = "ForceApplyCapacityChange"
  }
  storage_encrypted = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [
    aws_security_group.aurora_security_group.arn
  ]
}

