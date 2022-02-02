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

#resource "aws_instance" "helloworld" {
#    ami = "ami-04505e74c0741db8d"
#    instance_type = "t2.micro"
#}

resource "aws_vpc" "vpc_brq" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "VPC_legal"
    }
}

# resource "aws_subnet" "BRQ_Subrede" {
#     vpc_id = aws_vpc.vpc_brq.id
#     cidr_block = "10.0.1.0/24"
#     tags = {
#       Name = "Subrede_BRQ"
#     }
# }

resource "aws_internet_gateway" "BRQ_gate" {
    vpc_id = aws_vpc.vpc_brq.id

    tags = {
        Name = "Gateway_BRQ"
    }
}