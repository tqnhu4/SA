# main.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# --- VPC and Networking ---

# Create a new VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-VPC"
  }
}

# Create Internet Gateway for public subnet outbound access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}

# Create Public Subnets (for ALB and NAT Gateway)
resource "aws_subnet" "public" {
  count             = length(var.public_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # EC2 instances launched here get public IPs

  tags = {
    Name = "${var.project_name}-PublicSubnet-${count.index + 1}"
  }
}

# Create Private Subnets (for EC2 instances and RDS)
resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-PrivateSubnet-${count.index + 1}"
  }
}

# Data source to get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.main] # Ensure IGW exists before EIP is associated with NAT GW

  tags = {
    Name = "${var.project_name}-NAT-EIP"
  }
}

# Create NAT Gateway in a public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public[0].id # Place NAT Gateway in the first public subnet
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-NAT-Gateway"
  }
}

# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-PublicRT"
  }
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id # Route outbound internet traffic through NAT Gateway
  }

  tags = {
    Name = "${var.project_name}-PrivateRT"
  }
}

# Associate Private Route Table with Private Subnets
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- Security Groups ---

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.project_name}-ALB-SG-"
  description = "Allow HTTP/HTTPS inbound to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Optional: Add HTTPS if you plan to use SSL/TLS
  # ingress {
  #   description = "Allow HTTPS from anywhere"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ALB-SG"
  }
}

# Security Group for EC2 Application Layer
resource "aws_security_group" "app_sg" {
  name_prefix = "${var.project_name}-App-SG-"
  description = "Allow HTTP from ALB and SSH from specific IP"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP (Port 80) from ALB Security Group
  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow SSH (Port 22) from your public IP for management
  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_public_ip] # Your public IP for SSH access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic (e.g., to RDS, internet via NAT GW)
  }

  tags = {
    Name = "${var.project_name}-App-SG"
  }
}

# Security Group for RDS Database Layer
resource "aws_security_group" "db_sg" {
  name_prefix = "${var.project_name}-DB-SG-"
  description = "Allow MySQL inbound from Application Security Group"
  vpc_id      = aws_vpc.main.id

  # Allow MySQL (Port 3306) from EC2 Application Security Group
  ingress {
    description     = "Allow MySQL from App Servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic (e.g., for updates, backups)
  }

  tags = {
    Name = "${var.project_name}-DB-SG"
  }
}

# --- EC2 Application Layer ---

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

# Create an SSH Key Pair
resource "aws_key_pair" "my_key_pair" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)

  tags = {
    Name = "${var.project_name}-Key-Pair"
  }
}

# EC2 Instances (e.g., 2 instances for high availability)
resource "aws_instance" "app_server" {
  count         = var.ec2_instance_count
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2_instance_type
  key_name      = aws_key_pair.my_key_pair.key_name
  subnet_id     = aws_subnet.private[count.index].id # Deploy in private subnets
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # User data to install Nginx and a simple index.html
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "<h1>Hello from EC2 App Server ${count.index + 1}!</h1>" | sudo tee /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name        = "${var.project_name}-AppServer-${count.index + 1}"
    Environment = "Dev"
    Layer       = "Application"
  }
}

# --- Application Load Balancer (ALB) ---

resource "aws_lb" "main" {
  name               = "${var.project_name}-ALB"
  internal           = false # Public-facing ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in aws_subnet.public : s.id] # Deploy in public subnets

  tags = {
    Name = "${var.project_name}-ALB"
  }
}

resource "aws_lb_target_group" "app_servers" {
  name     = "${var.project_name}-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-App-TargetGroup"
  }
}

# Register EC2 instances with the Target Group
resource "aws_lb_target_group_attachment" "app_server_attach" {
  count            = var.ec2_instance_count
  target_group_arn = aws_lb_target_group.app_servers.arn
  target_id        = aws_instance.app_server[count.index].id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_servers.arn
  }
}

# --- RDS MySQL Database Layer ---

# Create a DB Subnet Group for RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id] # RDS must be in private subnets

  tags = {
    Name = "${var.project_name}-DB-Subnet-Group"
  }
}

# Create RDS MySQL Instance
resource "aws_db_instance" "mysql_db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.35" # Specify a stable MySQL 8.0 version
  instance_class       = var.rds_instance_type
  db_name              = var.rds_db_name
  username             = var.rds_username
  password             = var.rds_password
  parameter_group_name = "default.mysql8.0" # Default parameter group for MySQL 8.0
  skip_final_snapshot  = true # Set to false for production
  multi_az             = false # Set to true for production for high availability
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible  = false # Crucial: Keep database private

  tags = {
    Name        = "${var.project_name}-MySQL-DB"
    Environment = "Dev"
    Layer       = "Database"
  }
}

# --- Outputs ---

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "web_server_ssh_commands" {
  description = "SSH commands for the EC2 instances."
  value = {
    for i, instance in aws_instance.app_server :
    "AppServer-${i + 1}" => "ssh -i ${var.private_key_path} ec2-user@${instance.public_ip}"
  }
}

output "rds_endpoint" {
  description = "The endpoint of the RDS MySQL database."
  value       = aws_db_instance.mysql_db.address
}

output "rds_port" {
  description = "The port of the RDS MySQL database."
  value       = aws_db_instance.mysql_db.port
}

output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}