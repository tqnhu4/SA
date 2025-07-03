# main.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Lookup the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a Security Group to allow SSH (Port 22) access
resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2-ssh-sg-"
  description = "Allow SSH inbound traffic"
  vpc_id      = var.aws_vpc_id # Assume a default VPC ID if not specified in variables

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: 0.0.0.0/0 allows access from anywhere.
                               # For production, restrict to specific IPs/CIDR blocks.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2-SSH-SecurityGroup"
  }
}

# Create an EC2 Instance
resource "aws_instance" "my_ec2_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name        = "MySimpleEC2Instance"
    Environment = "Dev"
  }
}

# Create an SSH Key Pair
resource "aws_key_pair" "my_key_pair" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}

# Output the Public IP of the EC2 Instance
output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.my_ec2_instance.public_ip
}

# Output the SSH command
output "ssh_command" {
  description = "Command to SSH into the EC2 instance."
  value       = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.my_ec2_instance.public_ip}"
}