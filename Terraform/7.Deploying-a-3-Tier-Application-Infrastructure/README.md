-----

## Lesson 7: Deploying a 3-Tier Application Infrastructure

This project demonstrates how to build a common 3-tier architecture on AWS using Terraform. This architecture separates concerns into distinct layers: presentation (ALB), application (EC2), and data (RDS).

You'll learn about:

1.  **Custom VPC and Subnets:** Creating a dedicated network environment with public and private subnets.
2.  **Internet Gateway & NAT Gateway:** Enabling internet access for public and private resources.
3.  **Application Load Balancer (ALB):** Distributing incoming traffic to your application servers.
4.  **EC2 Application Layer:** Deploying web servers in private subnets for security.
5.  **RDS MySQL Database:** Setting up a managed relational database in private subnets.
6.  **Security Groups:** Implementing network access control between layers.
7.  **Inter-Layer Connectivity:** Ensuring proper routing and security for communication between ALB, EC2, and RDS.

-----

### Architecture Overview

  * **Public Subnets:** Hosts the ALB and NAT Gateway. Resources here have direct internet access.
  * **Private Subnets:** Hosts EC2 instances (application layer) and RDS database. Resources here can only be accessed from within the VPC or via the NAT Gateway for outbound internet access.
  * **ALB:** Listens on public subnets and forwards traffic to EC2 instances.
  * **EC2 Instances:** Run your application (e.g., a web server), accessible via the ALB.
  * **RDS MySQL:** The database, only accessible from the EC2 instances in the private subnets.

-----

### Prerequisites

Before you begin, ensure you have the following:

1.  **AWS Account:** An active AWS account.
2.  **AWS CLI Configured:** Terraform uses your AWS CLI configuration for authentication. Ensure your IAM user has permissions to create VPCs, subnets, gateways, security groups, EC2 instances, ALBs, RDS instances, etc.
3.  **Terraform Installed:** As per previous lessons.
4.  **SSH Key Pair:** You should have an SSH key pair ready (e.g., `~/.ssh/my_aws_key_sg.pub` and `~/.ssh/my_aws_key_sg`).

-----

### Step 1: Create a New Project Directory

Create a new directory for this project and navigate into it:

```bash
mkdir terraform-3-tier-app
cd terraform-3-tier-app
```

-----

### Step 2: Define the Terraform Configuration (`main.tf`)

Create a file named `main.tf` in your `terraform-3-tier-app` directory and add the following content. This file will contain all the necessary AWS resources for your 3-tier application.

```terraform
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
```

**Explanation of `main.tf`:**

  * **VPC and Networking:**
      * `aws_vpc`: Creates a new Virtual Private Cloud with a specified CIDR block.
      * `aws_internet_gateway`: Allows communication between your VPC and the internet.
      * `aws_subnet.public` & `aws_subnet.private`: Creates multiple public and private subnets across different Availability Zones (AZs) for high availability. `map_public_ip_on_launch` is `true` for public subnets, `false` for private.
      * `data "aws_availability_zones"`: Dynamically fetches available AZs in your chosen region.
      * `aws_eip.nat_gateway_eip` & `aws_nat_gateway.main`: A NAT Gateway in a public subnet allows instances in private subnets to initiate outbound connections to the internet (e.g., for updates, downloading packages) without being publicly accessible.
      * `aws_route_table.public` & `aws_route_table.private`: Define routing rules. The public route table points `0.0.0.0/0` to the Internet Gateway. The private route table points `0.0.0.0/0` to the NAT Gateway.
      * `aws_route_table_association`: Associates the route tables with their respective subnets.
  * **Security Groups:**
      * `aws_security_group.alb_sg`: Allows HTTP (port 80) from anywhere to the ALB.
      * `aws_security_group.app_sg`: Allows HTTP (port 80) *only from the ALB's security group* and SSH (port 22) from *your specific public IP*. This ensures only the ALB can talk to your web servers on port 80.
      * `aws_security_group.db_sg`: Allows MySQL (port 3306) *only from the EC2 application security group*. This ensures only your application servers can connect to the database.
  * **EC2 Application Layer:**
      * `data "aws_ami"`: Fetches the latest Amazon Linux 2 AMI.
      * `aws_key_pair`: Creates an SSH key pair in AWS.
      * `aws_instance.app_server`: Creates multiple EC2 instances in the private subnets.
          * `user_data`: A shell script that installs and configures Nginx as a simple web server.
  * **Application Load Balancer (ALB):**
      * `aws_lb.main`: Creates the ALB, which is `internal = false` (public-facing) and deployed across the public subnets.
      * `aws_lb_target_group.app_servers`: Defines a target group where your EC2 instances will be registered. It includes a health check to monitor the instances.
      * `aws_lb_target_group_attachment`: Registers each EC2 instance with the target group.
      * `aws_lb_listener.http`: Configures the ALB to listen on port 80 (HTTP) and forward traffic to the `app_servers` target group.
  * **RDS MySQL Database Layer:**
      * `aws_db_subnet_group.main`: A DB subnet group is required for RDS instances. It must span at least two private subnets.
      * `aws_db_instance.mysql_db`: Creates the MySQL database instance.
          * `publicly_accessible = false`: **Crucial for security.** Ensures the database is not directly accessible from the internet.
          * `vpc_security_group_ids`: Associates the database with its dedicated security group.
          * `db_subnet_group_name`: Links to the DB subnet group.
          * `skip_final_snapshot = true`: Set to `false` in production to ensure a final snapshot before deletion.
          * `multi_az = false`: Set to `true` in production for high availability and failover.
  * **Outputs:** Provides useful information like the ALB DNS name, SSH commands for EC2 instances, and RDS endpoint details.

-----

### Step 3: Define Variables (`variables.tf`)

Create a file named `variables.tf` in the same directory:

```terraform
# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1" # Or your preferred region, e.g., "ap-southeast-1"
}

variable "project_name" {
  description = "A unique name for your project, used for resource naming."
  type        = string
  default     = "ThreeTierApp"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "List of CIDR blocks for public subnets (must match count of AZs)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # Example for 2 AZs
}

variable "private_subnets_cidr" {
  description = "List of CIDR blocks for private subnets (must match count of AZs)."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"] # Example for 2 AZs
}

variable "my_public_ip" {
  description = "Your local machine's public IP address in CIDR notation (e.g., 'X.X.X.X/32') for SSH access."
  type        = string
}

variable "key_pair_name" {
  description = "The name for the AWS SSH key pair."
  type        = string
}

variable "public_key_path" {
  description = "The file path to your public SSH key (e.g., ~/.ssh/id_rsa.pub)."
  type        = string
}

variable "private_key_path" {
  description = "The file path to your private SSH key (e.g., ~/.ssh/id_rsa) for SSH command output."
  type        = string
}

variable "ec2_instance_type" {
  description = "The EC2 instance type for the application servers."
  type        = string
  default     = "t2.micro" # Free tier eligible
}

variable "ec2_instance_count" {
  description = "The number of EC2 instances to deploy in the application layer."
  type        = number
  default     = 2 # Deploy 2 instances for load balancing
}

variable "rds_instance_type" {
  description = "The RDS instance type for the MySQL database."
  type        = string
  default     = "db.t3.micro" # Free tier eligible for some usage, check AWS docs
}

variable "rds_db_name" {
  description = "The name of the RDS database."
  type        = string
  default     = "myappdb"
}

variable "rds_username" {
  description = "The master username for the RDS database."
  type        = string
}

variable "rds_password" {
  description = "The master password for the RDS database."
  type        = string
  sensitive   = true # Mark as sensitive to prevent it from being displayed in logs
}
```

-----

### Step 4: Provide Variable Values (`terraform.tfvars`)

Create a file named `terraform.tfvars` in your `terraform-3-tier-app` directory. **Update all placeholder values with your actual information.**

```terraform
# terraform.tfvars

aws_region        = "us-east-1" # Choose your desired region
project_name      = "My3TierApp"

# Replace X.X.X.X with your actual public IP address (e.g., "203.0.113.45/32")
my_public_ip      = "X.X.X.X/32"

# Paths to your SSH key pair
key_pair_name     = "my-3tier-app-key-$(date +%s)" # Unique name for your key pair in AWS
public_key_path   = "/home/your_user/.ssh/my_aws_key_sg.pub" # <--- IMPORTANT: Update with your actual public key path
private_key_path  = "/home/your_user/.ssh/my_aws_key_sg"    # <--- IMPORTANT: Update with your actual private key path

# RDS Database Credentials (CHANGE THESE!)
rds_username      = "admin"
rds_password      = "MySuperStrongPassword123!" # <--- IMPORTANT: Use a strong, unique password
```

**How to find `my_public_ip`:**
Open your browser and search for "what is my ip". It will usually show your current public IP address. Append `/32` to it (e.g., if your IP is `203.0.113.45`, use `203.0.113.45/32`) as CIDR block notation.

-----

### Step 5: Run Terraform Commands

Navigate to your `terraform-3-tier-app/` directory.

#### `terraform init`

Initialize Terraform. This downloads the AWS provider.

```bash
terraform init
```

#### `terraform plan`

Review the execution plan. This will show you all the resources Terraform intends to create (VPC, subnets, gateways, security groups, EC2 instances, ALB, RDS). This will be a long list\!

```bash
terraform plan
```

Carefully inspect the plan to ensure it aligns with your expectations.

#### `terraform apply`

Execute the plan to deploy the infrastructure. This process will take a significant amount of time (10-15 minutes or more) as AWS provisions the various services, especially the RDS instance.

```bash
terraform apply
```

Terraform will display the plan again and ask for confirmation. Type `yes` and press Enter.

Once complete, you will see the outputs for your ALB DNS name, SSH commands for EC2 instances, and RDS endpoint details.

```
...
Apply complete! Resources: XX added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name = "my-3tier-app-alb-XXXXXXXX.us-east-1.elb.amazonaws.com"
rds_endpoint = "my-3tier-app-mysql-db.XXXXXXXX.us-east-1.rds.amazonaws.com"
rds_port = 3306
web_server_ssh_commands = {
  "AppServer-1" = "ssh -i /home/your_user/.ssh/my_aws_key_sg ec2-user@X.X.X.X"
  "AppServer-2" = "ssh -i /home/your_user/.ssh/my_aws_key_sg ec2-user@Y.Y.Y.Y"
}
vpc_id = "vpc-XXXXXXXX"
```

#### Test Your Deployment

1.  **Access the Web Application:** Open your web browser and navigate to the `alb_dns_name` provided in the outputs. You should see "Hello from EC2 App Server 1\!" or "Hello from EC2 App Server 2\!", indicating that the ALB is distributing traffic to your EC2 instances. Refresh a few times to see if it switches between the two messages.
2.  **SSH into EC2 Instances:** Use the `web_server_ssh_commands` to connect to your EC2 instances. From there, you can try to connect to the RDS database using the `rds_endpoint` and `rds_port` (e.g., `mysql -h <rds_endpoint> -P 3306 -u <rds_username> -p`).

#### `terraform destroy`

When you're done testing, **it is crucial to destroy all resources** to avoid incurring significant AWS costs, especially for the NAT Gateway and RDS instance.

```bash
terraform destroy
```

Terraform will display all the resources it plans to destroy. Type `yes` and press Enter to confirm. This process will also take some time.


