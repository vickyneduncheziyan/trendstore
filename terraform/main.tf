provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "open_sg" {
  name        = "open-all-ports-sg"
  description = "Allow all inbound and outbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "open-all-ports-sg"
  }
}

resource "aws_instance" "my_ec2" {
  ami                         = "ami-05d2d839d4f73aafb"
  instance_type               = "t3.small"
  vpc_security_group_ids      = [aws_security_group.open_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "jenkins controller"
  }
}

output "instance_id" {
  value = aws_instance.my_ec2.id
}

output "public_ip" {
  value = aws_instance.my_ec2.public_ip
}
