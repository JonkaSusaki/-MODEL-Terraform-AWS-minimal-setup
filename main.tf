terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Local variables
locals {
  env     = "dev"
  ec2_ami = "ami-0b04486d62582a5b9" # Ubuntu 24.04 LTS AMD64 (sa-east-1)

  region             = "sa-east-1"
  availability_zone1 = "sa-east-1a"
  availability_zone2 = "sa-east-1b"

  db_name     = "test"
  db_username = "postgres"
  db_password = "gK1_sm3wTa25fLXOgrsQ"
  db_port     = 5432

  ec2_ssh_key = file("~/.ssh/id_rsa.pub")

  # CIDR blocks (for VPC, subnets, etc.)
  vpc_cidr           = "10.0.0.0/16"
  private_zone1_cidr = "10.0.0.0/24"
  private_zone2_cidr = "10.0.1.0/24"
  public_zone1_cidr  = "10.0.2.0/24"
}

# Configure AWS Provider
provider "aws" {
  region = local.region
}


# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.env}-main"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.env}-main"
  }
}

# Create Public Subnet 1 (for EC2)
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_zone1_cidr
  availability_zone = local.availability_zone1

  tags = {
    Name = "${local.env}-public-subnet"
  }
}

# Create Private Subnet 1 (for RDS)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_zone1_cidr
  availability_zone = local.availability_zone1

  tags = {
    Name = "${local.env}-private-subnet-1"
  }
}

# Create Private Subnet 2 (for RDS)
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_zone2_cidr
  availability_zone = local.availability_zone2

  tags = {
    Name = "${local.env}-private-subnet-2"
  }
}

# Create Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.env}-public-route-table"
  }
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}


# Create Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "rds-security-group"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }
}

# Create Security Group for EC2
resource "aws_security_group" "ec2" {
  name        = "ec2-security-group"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "subnet_group_dev" {
  name = "rds-subnet-group"

  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

}

# Create RDS PostgreSQL Instance
# resource "aws_db_instance" "rds_instance" {
#   allocated_storage      = 10
#   identifier             = "${local.env}-rds-instance"
#   instance_class         = "db.t4g.micro"
#   engine                 = "postgres"
#   engine_version         = "17.4"
#   db_subnet_group_name   = aws_db_subnet_group.subnet_group_dev.name
#   vpc_security_group_ids = [aws_security_group.rds.id]

#   skip_final_snapshot = true

#   db_name  = local.db_name
#   username = local.db_username
#   password = local.db_password
#   port     = local.db_port

# }

resource "aws_key_pair" "app_server" {
  key_name   = "${local.env}-key-name"
  public_key = local.ec2_ssh_key
}

# Create EC2 Instance
resource "aws_instance" "app_server" {
  ami                         = local.ec2_ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  key_name = aws_key_pair.app_server.key_name

  tags = {
    Name = "${local.env}-ec2-instance"
  }
}

module "s3" {
  source = "./s3"
  env    = local.env
}

# Output values
# output "rds_endpoint" {
#   value = aws_db_instance.rds_instance.address
# }

output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "ec2_public_dns" {
  value = aws_instance.app_server.public_dns
}
