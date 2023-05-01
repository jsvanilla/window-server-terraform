provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "windows_server" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example_vpc"
  }
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "example_subnet"
  }
}

resource "aws_instance" "name" {
  count         = 3
  ami           = data.aws_ami.windows_server.id
  instance_type = "t2.micro"
  key_name      = "terraform_ec2"
  subnet_id     = aws_subnet.example.id

  tags = {
    Name = "terraform_ec2"
  }
}

output "public_ips" {
  value = [for instance in aws_instance.name : instance.public_ip]
}
