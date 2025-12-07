###############################################
# TERRAFORM: FULLY AUTOMATED SQL SERVER RDS
###############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

###############################################
# RANDOM GENERATED VALUES
###############################################

resource "random_pet" "db_name" {
  length = 2
}

resource "random_string" "username" {
  length  = 8
  upper   = false
  special = false
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@#!"
}

###############################################
# USE DEFAULT VPC + DEFAULT SUBNETS
###############################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

###############################################
# SECURITY GROUP – ALLOW SQL SERVER
###############################################

resource "aws_security_group" "sql_sg" {
  name        = "sql-server-auto-sg"
  description = "Allow SQL Server access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Adjust if needed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############################################
# RDS SUBNET GROUP
###############################################

resource "aws_db_subnet_group" "sql_subnets" {
  name       = "sql-default-subnets"
  subnet_ids = data.aws_subnets.default.ids
}

###############################################
# RDS INSTANCE (SQL SERVER EXPRESS – FREE TIER)
###############################################

resource "aws_db_instance" "sqlserver" {
  identifier               = random_pet.db_name.id
  engine                   = "sqlserver-ex"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20

  username = random_string.username.result
  password = random_password.password.result

  db_subnet_group_name   = aws_db_subnet_group.sql_subnets.name
  vpc_security_group_ids = [aws_security_group.sql_sg.id]

  publicly_accessible = true
  skip_final_snapshot = true
}

###############################################
# OUTPUTS
###############################################

output "rds_host" {
  value = aws_db_instance.sqlserver.address
}

output "rds_port" {
  value = aws_db_instance.sqlserver.port
}

output "username" {
  value = random_string.username.result
}

output "password" {
  value     = random_password.password.result
  sensitive = true
}

output "database_identifier" {
  value = random_pet.db_name.id
}
