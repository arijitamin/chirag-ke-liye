# Terraform Dependencies
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
   backend "s3" {
    bucket         = "medusa-bucket-name"
   region = "ap-south-1"
   key    = "terraform.tfstate"
   dynamodb_table = "medusa-lock-table"
    encrypt        = true
 }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}


# ======================================================================================
# VPC 
# ======================================================================================

resource "aws_vpc" "medusa_vpc" {
  cidr_block = "10.50.0.0/22"
}

# ======================================================================================
# Subnets 
# ======================================================================================

resource "aws_subnet" "medusa_app_pvt" {
  vpc_id     = aws_vpc.medusa_vpc.id
  cidr_block = "10.50.0.0/23"

  tags = {
    Name = "private_app"
  }
}

resource "aws_subnet" "medusa_app_persistance" {
  vpc_id     = aws_vpc.medusa_vpc.id
  cidr_block = "10.50.2.0/24"

  tags = {
    Name = "private_persistance"
  }
}

resource "aws_subnet" "medusa_app_public" {
  vpc_id     = aws_vpc.medusa_vpc.id
  cidr_block = "10.50.3.0/24"

  tags = {
    Name = "public"
  }
}

# ======================================================================================
# IGW
# ======================================================================================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.medusa_vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_internet_gateway_attachment" "igw_attach" {
  internet_gateway_id = aws_internet_gateway.igw.id
  vpc_id              = aws_vpc.medusa_vpc.id
}

# ======================================================================================
# NAT Gateway
# ======================================================================================

resource "aws_eip" "nat_eip" {
  domain           = "vpc"
  public_ipv4_pool = "amazon"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.medusa_app_public.id

  tags = {
    Name = "nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# ======================================================================================
# Load Balancer
# ======================================================================================

resource "aws_alb" "application_load_balancer" {
  name               = "medusa-dev-load-balancer"
  load_balancer_type = "application"
  subnets = [ 
    "${aws_subnet.medusa_app_pvt.id}"
  ]
  security_groups = ["${aws_security_group.load_balancer_sg.id}"]
}

resource "aws_security_group" "load_balancer_sg" {
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_lb_target_group" "tg" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.medusa_vpc.id}"
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }
}