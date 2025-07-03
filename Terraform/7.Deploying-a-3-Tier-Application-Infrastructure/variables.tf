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