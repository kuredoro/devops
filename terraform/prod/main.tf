terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"

  backend "remote" {
    organization = "pytime"

    workspaces {
      name = "prod"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "pytime_prod"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "pytime_prod_ig"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "pytime_prod_subnet"
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "pytime_prod_instance"
  description = "Used python time server prod instances"
  vpc_id      = aws_vpc.default.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our elb security group to access
# the ELB over HTTP
resource "aws_security_group" "elb" {
  name        = "pytime_prod_elb_sg"
  description = "Used in the pytime server prod elb"

  vpc_id = aws_vpc.default.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ensure the VPC has an Internet gateway or this step will fail
  depends_on = [aws_internet_gateway.default]
}

resource "aws_elb" "web" {
  name     = "pytime-elb"
  internal = false

  subnets = [aws_subnet.default.id]

  security_groups = [aws_security_group.elb.id]

  # The same availability zone as our instance
  availability_zones = aws_instance.web[*].availability_zone

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  # The instance is registered automatically
  instances                   = aws_instance.web[*].id
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "web" {
  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = var.aws_amis[var.aws_region]

  # The name of our SSH keypair we created above.
  key_name = aws_key_pair.auth.id

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.default.id]
  subnet_id              = aws_subnet.default.id
  user_data              = file("userdata.sh")

  count = 4

  #Instance tags
  tags = {
    Name = "pytime"
  }
}
