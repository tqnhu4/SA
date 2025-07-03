# main.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# --- Network and EC2 Setup (from previous lessons, simplified) ---

# Data source to get information about the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get information about default subnets
data "aws_subnet_ids" "default_subnets" {
  vpc_id = data.aws_vpc.default.id
}

# Data source to get available AZs (to pick a default subnet)
data "aws_availability_zones" "available" {
  state = "available"
}

# Lookup the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create an SSH Key Pair
resource "aws_key_pair" "my_key_pair" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}

# Create a Security Group for EC2 (allowing SSH from your IP)
resource "aws_security_group" "ec2_sg" {
  name_prefix = "${var.project_name}-EC2-SG-"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_public_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-EC2-SecurityGroup"
  }
}

# Create an EC2 Instance to monitor
resource "aws_instance" "monitored_ec2" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2_instance_type
  key_name      = aws_key_pair.my_key_pair.key_name
  # Pick the first default subnet for simplicity
  subnet_id     = data.aws_subnet_ids.default_subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name        = "${var.project_name}-MonitoredEC2"
    Environment = "Dev"
  }
}

# --- CloudWatch Alarm and SNS Topic ---

# 1. Create an SNS Topic for notifications
resource "aws_sns_topic" "cpu_alarm_topic" {
  name = "${var.project_name}-CPU-Alarm-Topic"

  tags = {
    Name = "${var.project_name}-CPU-Alarm-SNS-Topic"
  }
}

# 2. Subscribe an email address to the SNS topic
# IMPORTANT: You will receive a confirmation email. You MUST confirm the subscription
# by clicking the link in the email before notifications will be sent.
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cpu_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email_address
}

# 3. Create a CloudWatch CPU Utilization Alarm for the EC2 instance
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "${var.project_name}-EC2-CPU-High-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1" # Number of periods to evaluate
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300" # 5 minutes (in seconds)
  statistic           = "Average"
  threshold           = var.cpu_threshold_percent # e.g., 80
  alarm_description   = "This alarm monitors EC2 CPU utilization."
  actions_enabled     = true # Ensure actions are enabled

  # Specify the EC2 instance to monitor
  dimensions = {
    InstanceId = aws_instance.monitored_ec2.id
  }

  # When the alarm state changes to ALARM, send a notification to the SNS topic
  alarm_actions = [aws_sns_topic.cpu_alarm_topic.arn]
  # Optional: actions to take when alarm state goes to OK or INSUFFICIENT_DATA
  ok_actions = [aws_sns_topic.cpu_alarm_topic.arn]
  insufficient_data_actions = [aws_sns_topic.cpu_alarm_topic.arn]

  tags = {
    Name = "${var.project_name}-CPU-Alarm"
  }
}

# --- Outputs ---

output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.monitored_ec2.public_ip
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic."
  value       = aws_sns_topic.cpu_alarm_topic.arn
}

output "cloudwatch_alarm_name" {
  description = "The name of the CloudWatch alarm."
  value       = aws_cloudwatch_metric_alarm.cpu_utilization_alarm.alarm_name
}

output "ssh_command" {
  description = "Command to SSH into the EC2 instance."
  value       = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.monitored_ec2.public_ip}"
}