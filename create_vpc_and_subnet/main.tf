provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "main-subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.main-vpc.id
}