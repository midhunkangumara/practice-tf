#terraform {
#  required_providers {
#    aws = {
#      source  = "hashicorp/aws"
#      version = "~> 3.0"
#    }
#  }
#}
variable "access_key" {
  description = "for access"
}
variable "secret_key" {
  description = "for secret key"
  
}
provider "aws" {
  region = "ap-south-1"
  access_key = var.access_key
  secret_key = var.secret_key
}
#1. creat vpc
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
    tags = {
    Name = "my_vpc"
  }
}
#2. create internet gateway


resource "aws_internet_gateway" "my_gw" {
  vpc_id = aws_vpc.my_vpc.id
}
#3. create route table
resource "aws_route_table" "my_rout_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.my_gw.id
  }

  tags = {
    Name = "my_rout"
  }
}
#4. subnet

resource "aws_subnet" "my_subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1b"

    tags = {
        Name= "my_sub"
    }
  
}

#5. assosiate subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_rout_table.id
}

#6. create a security group

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   ingress {
    description      = "HTTPS"
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
   
  }

  tags = {
    Name = "allow_web"
  }
}

#7. create network interface with an ip in the subnet the we created before

resource "aws_network_interface" "web_server" {
  subnet_id       = aws_subnet.my_subnet.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.allow_web.id]

}



#8. assing an ellastic ip adderss
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_server.id
  associate_with_private_ip = "10.0.0.10"
  depends_on = [
    aws_internet_gateway.my_gw
  ]

}

#9. crate an ubuntu server



resource "aws_instance" "web_server" {
    ami = "ami-0756a1c858554433e"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1b"
    key_name = "awsclass"
    
    
  network_interface {
      device_index=0
      network_interface_id = aws_network_interface.web_server.id
  }
  user_data = <<-EOF
          #!/bin/bash
          sudo apt update -y
          sudo apt install apache2 -y
          sudo systemctl start apache2
          sudo bash -c 'echo my first web server > /var/www/html/index.html'
          EOF
   tags =  {
       Name= "my-webserver"
   }

}










