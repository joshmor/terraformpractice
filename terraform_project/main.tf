provider "aws" {
  region = "us-east-1"
}
# 1. Create vpc

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "project_vpc"
  }
}

# 2. Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}

# 3. Create Custom Route Table

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.open_cidr_block_vp4
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Project_Route_Table"
  }
}
# 4. Create a Subnet (important to hardcode availability zone for sub net and ec2 to force them to be the same)

resource "aws_subnet" "subnet_project" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.main_vpc.id
  availability_zone = "us-east-1a"

  tags = {
    Name = "Project_subnet"
  }
}
# 5. Associate subnet with Route Table

resource "aws_route_table_association" "rta" {
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.subnet_project.id
}
# 6. Create Security Group to allow port 22,80,443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [var.open_cidr_block_vp4]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [var.open_cidr_block_vp4]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.open_cidr_block_vp4]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.open_cidr_block_vp4]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}
# 7. Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web-server-josh" {
  subnet_id       = aws_subnet.subnet_project.id
  private_ips     = [var.private_ip_address]
  security_groups = [aws_security_group.allow_web.id]

}
# 8. Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "eip" {
  vpc = true
  network_interface = aws_network_interface.web-server-josh.id
  associate_with_private_ip = var.private_ip_address
  depends_on = [aws_internet_gateway.gw]
}
#prints out output after applying

output "server_public_ip" {
  value = aws_eip.eip.public_ip
}
# 9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "web-server-instance" {
  ami = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-josh.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very fist web server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "web-server"
  }

}