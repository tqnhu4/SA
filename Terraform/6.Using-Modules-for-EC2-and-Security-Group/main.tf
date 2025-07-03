# main.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source to get information about the default VPC
data "aws_vpc" "default" {
  default = true
}

# Resource to create an SSH Key Pair in AWS
resource "aws_key_pair" "my_key_pair" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}

# --- Call the Security Group Module for Web Server SG ---
module "web_server_sg" {
  source = "./modules/security_group" # Path to our local security_group module

  name_prefix = "web-sg"
  description = "Security Group for Web Servers (SSH and HTTP)"
  vpc_id      = data.aws_vpc.default.id

  ingress_rules = [
    {
      description = "Allow SSH from my IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.my_public_ip] # Use your actual public IP for SSH
      security_groups = []
    },
    {
      description = "Allow HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      security_groups = []
    },
  ]

  tags = {
    Project     = "ModuleDemo"
    ManagedBy   = "Terraform"
    Purpose     = "WebServer"
  }
}

# --- Call the EC2 Instance Module for Web Server 1 ---
module "web_server_01" {
  source = "./modules/ec2_instance" # Path to our local ec2_instance module

  instance_name      = "WebServer-01"
  instance_type      = "t2.micro"
  key_name           = aws_key_pair.my_key_pair.key_name
  security_group_ids = [module.web_server_sg.security_group_id]
  subnet_id          = data.aws_vpc.default.default_route_table_id # Or specify a specific subnet

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "<h1>Hello from Web Server 01!</h1>" | sudo tee /usr/share/nginx/html/index.html
              EOF

  tags = {
    Project     = "ModuleDemo"
    ManagedBy   = "Terraform"
    Role        = "Webserver"
  }
}

# --- Call the EC2 Instance Module for Web Server 2 (with a different instance type) ---
module "web_server_02" {
  source = "./modules/ec2_instance"

  instance_name      = "WebServer-02"
  instance_type      = "t2.small" # Different instance type
  key_name           = aws_key_pair.my_key_pair.key_name
  security_group_ids = [module.web_server_sg.security_group_id] # Reusing the same SG
  subnet_id          = data.aws_vpc.default.default_route_table_id

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y apache2 # Using Apache for variety
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from Web Server 02 (Apache)!</h1>" | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Project     = "ModuleDemo"
    ManagedBy   = "Terraform"
    Role        = "Webserver"
  }
}

# Output the Public IPs
output "web_server_01_public_ip" {
  description = "Public IP of Web Server 01."
  value       = module.web_server_01.instance_public_ip
}

output "web_server_02_public_ip" {
  description = "Public IP of Web Server 02."
  value       = module.web_server_02.instance_public_ip
}

# Output SSH Commands
output "web_server_01_ssh_command" {
  description = "SSH command for Web Server 01."
  value       = "ssh -i ${var.private_key_path} ec2-user@${module.web_server_01.instance_public_ip}"
}

output "web_server_02_ssh_command" {
  description = "SSH command for Web Server 02."
  value       = "ssh -i ${var.private_key_path} ec2-user@${module.web_server_02.instance_public_ip}"
}

# Output HTTP URLs
output "web_server_01_http_url" {
  description = "HTTP URL for Web Server 01 (Nginx)."
  value       = "http://${module.web_server_01.instance_public_ip}"
}

output "web_server_02_http_url" {
  description = "HTTP URL for Web Server 02 (Apache)."
  value       = "http://${module.web_server_02.instance_public_ip}"
}