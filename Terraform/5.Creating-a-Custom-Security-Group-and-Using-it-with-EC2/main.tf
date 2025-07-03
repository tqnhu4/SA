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

# Create a Custom Security Group to allow SSH (Port 22) and HTTP (Port 80) access
resource "aws_security_group" "custom_ec2_sg" {
  name_prefix = "custom-ec2-sg-"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = var.aws_vpc_id # Use default VPC ID if not specified in variables

  # Ingress rule for SSH (Port 22)
  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For production, restrict to specific IPs/CIDR blocks.
  }

  # Ingress rule for HTTP (Port 80)
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For production, restrict to specific IPs/CIDR blocks.
  }

  # Egress rule (allow all outbound traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Custom-EC2-SecurityGroup"
  }
}

# Create an EC2 Instance
resource "aws_instance" "my_ec2_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.custom_ec2_sg.id] # Attach our custom SG

  tags = {
    Name        = "MyCustomSGEc2Instance"
    Environment = "Dev"
  }

  # User data to install Nginx for testing Port 80
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "<h1>Hello from your EC2 instance!</h1>" | sudo tee /usr/share/nginx/html/index.html
              EOF
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

# Output the HTTP URL
output "http_url" {
  description = "The URL to access the web server on the EC2 instance."
  value       = "http://${aws_instance.my_ec2_instance.public_ip}"
}