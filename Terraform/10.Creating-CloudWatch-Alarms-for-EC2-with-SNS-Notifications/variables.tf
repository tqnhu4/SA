# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1" # Or your preferred region
}

variable "project_name" {
  description = "A unique name for your project, used for resource naming."
  type        = string
  default     = "EC2AlarmDemo"
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
  description = "The EC2 instance type for the monitored server."
  type        = string
  default     = "t2.micro" # Free tier eligible
}

variable "cpu_threshold_percent" {
  description = "The CPU utilization percentage that triggers the alarm."
  type        = number
  default     = 80 # Alarm when CPU is 80% or higher
}

variable "notification_email_address" {
  description = "The email address to receive CloudWatch alarm notifications."
  type        = string
}