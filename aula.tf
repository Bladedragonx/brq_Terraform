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

variable "aws_ip_public" {
  description = "Ip Publico da AWS"
  type = string
}

resource "aws_vpc" "vpc_brq" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "VPC_legal"
    }
}

resource "aws_internet_gateway" "brq_gate" {
    vpc_id = aws_vpc.vpc_brq.id
    tags = {
    	Name = "Gateway_BRQ"
    }
}

resource "aws_route_table" "brq_route" {
	vpc_id = aws_vpc.vpc_brq.id

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.brq_gate.id
	}

	route {
			ipv6_cidr_block = "::/0"
			gateway_id = aws_internet_gateway.brq_gate.id
	}

	tags = {
			Name = "Route_BRQ"
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

resource "aws_route_table_association" "associacao" {
	subnet_id = aws_subnet.brq_subrede.id
	route_table_id = aws_route_table.brq_route.id
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

resource "aws_network_interface" "interface_brq" {
	subnet_id       = aws_subnet.brq_subrede.id
	private_ips     = [var.aws_ip_public]
	security_groups = [aws_security_group.firewall_brq.id]
	tags = {
		Name = "BRQ_Interface"
	}
}

resource "aws_eip" "brq_pub_ip" {
	vpc                       = true
	network_interface         = aws_network_interface.interface_brq.id
	associate_with_private_ip = var.aws_ip_public
	depends_on                = [aws_internet_gateway.brq_gate]
}

resource "aws_instance" "app-brq" {
	ami               = "ami-04505e74c0741db8d"
	instance_type     = "t2.micro"
	availability_zone = "us-east-1a"
	network_interface {
		device_index         = 0
		network_interface_id = aws_network_interface.interface_brq.id
	}
	user_data = <<-EOF
		#! /bin/bash
		sudo apt-get update -y
		sudo apt-get install -y apache2
		sudo systemctl start apache2
		sudo systemctl enable apache2
		sudo bash -c 'echo "<h1>Testando HTML na AWS via Terraform - Patrick</h1>"  > /var/www/html/index.html'
	EOF
	tags = {
		Name = "Instance App Web"
	}
	key_name = "Minha Chave"
}

