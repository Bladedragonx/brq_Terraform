terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "3.74.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

# resource "aws_instance" "helloworld" {
#     ami = "ami-04505e74c0741db8d"
#     instance_type = "t2.micro"
# }

resource "aws_vpc" "vpc_brq" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "VPC_legal"
    }
}

resource "aws_subnet" "brq_subrede" {
    vpc_id = aws_vpc.vpc_brq.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
      Name = "Subrede_BRQ"
    }
}

resource "aws_internet_gateway" "BRQ_gate" {
    vpc_id = aws_vpc.vpc_brq.id
    tags = {
        Name = "Gateway_BRQ"
    }
}

resource "aws_route_table_association" "associacao" {
  subnet_id = aws_subnet.brq_subrede.id
  route_table_id = aws_route_table.brq_route.id
}

resource "aws_route_table" "brq_route" {
  vpc_id = aws_vpc.vpc_brq.id

  route {
    cidr_block = "0.0.0.0/24"
    gateway_id = aws_internet_gateway.BRQ_gate.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.BRQ_gate.id
  }

  tags = {
    Name = "Route_BRQ"
  }
}

resource "aws_security_group" "firewall_brq" {
  name        = "abrir portas"
  description = "Abrir porta 22 (SSH), 443 (HTTPS) e 80 (HTTP)"
  vpc_id      = aws_vpc.vpc_brq.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "brq_firewall"
  }
}