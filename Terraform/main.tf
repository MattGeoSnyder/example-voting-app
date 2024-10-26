terraform {
  required_providers {
	aws = {
		source = "hashicorp/aws"
		version = "~> 5.0"
	}
  }
}

variable "key_name" {
  description = "The name of the EC2 key pair"
  type        = string
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_vpc" "vnet" {
	cidr_block = "10.0.0.0/16"
	enable_dns_hostnames = true
	enable_dns_support = true
}

resource "aws_subnet" "subnet" {
	vpc_id = aws_vpc.vnet.id
	cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "igw" {
	vpc_id = aws_vpc.vnet.id
}

resource "aws_route_table" "route_table" {
	vpc_id = aws_vpc.vnet.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.igw.id
	}
}

resource "aws_route_table_association" "route_table_association" {
	subnet_id = aws_subnet.subnet.id
	route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "sg" {
	vpc_id = aws_vpc.vnet.id
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "aws_instance" {
	ami = "ami-06b21ccaeff8cd686"
	instance_type = "t3.large"
	key_name = var.key_name
	associate_public_ip_address = true

	subnet_id = aws_subnet.subnet.id
}


resource "aws_key_pair" "tf_key" {
	key_name = var.key_name
	public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
	algorithm = "RSA"
	rsa_bits = 4096
}

resource "local_file" "tf_key" {
	content = tls_private_key.rsa.private_key_pem
	filename = var.key_name
}
