
# Create a VPC Terraform-VPC
resource "aws_vpc" "terraform-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  enable_classiclink   = "false"
  instance_tenancy     = "default"
    tags = {
      Name = "terraform-vpc"
    }
}

#Create subnet public 1a
resource "aws_subnet" "terraform-subnet-public-1a" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" #it makes this a public subnet
  availability_zone       = "us-east-1a"
  tags = {
    Name = "terraform-subnet-public-1a"
  }
}

#Create subnet public 1b
resource "aws_subnet" "terraform-subnet-public-1b" {
vpc_id                  = aws_vpc.terraform-vpc.id
cidr_block              = "10.0.2.0/24"
map_public_ip_on_launch = "true" #it makes this a public subnet
availability_zone       = "us-east-1b"
tags = {
Name = "terraform-subnet-public-1b"
}
}

#Create subnet private 1a
resource "aws_subnet" "terraform-subnet-private-1a" {
vpc_id                  = aws_vpc.terraform-vpc.id
cidr_block              = "10.0.3.0/24"
# map_public_ip_on_launch = "true" #it makes this a public subnet
availability_zone       = "us-east-1a"
tags = {
Name = "terraform-subnet-public-1b"
}
}

#Create subnet private 1b
resource "aws_subnet" "terraform-subnet-private-1b" {
vpc_id                  = aws_vpc.terraform-vpc.id
cidr_block              = "10.0.4.0/24"
# map_public_ip_on_launch = "true" #it makes this a public subnet
availability_zone       = "us-east-1b"
tags = {
Name = "terraform-subnet-public-1b"
}
}
