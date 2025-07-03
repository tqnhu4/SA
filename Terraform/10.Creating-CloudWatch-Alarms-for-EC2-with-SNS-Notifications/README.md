
-----

## Lesson 10: Creating CloudWatch Alarms for EC2 with SNS Notifications

Monitoring is crucial for any production system. AWS CloudWatch allows you to collect and track metrics, set alarms, and react to changes in your AWS resources. This lesson focuses on setting up a **CloudWatch alarm** for an EC2 instance's CPU utilization and sending alerts via an **SNS (Simple Notification Service) topic** to an email address.

You'll learn about:

1.  **EC2 Instance Deployment:** A simple EC2 instance to monitor.
2.  **CloudWatch Metrics:** Understanding how CloudWatch collects metrics (like CPU Utilization).
3.  **CloudWatch Alarms:** Defining conditions that trigger an alert.
4.  **SNS Topic:** Creating a publish/subscribe messaging service to send notifications.
5.  **Connecting Alarm to SNS:** Linking the alarm to the SNS topic for email delivery.

-----

### Prerequisites

Before you begin, ensure you have the following:

1.  **AWS Account:** An active AWS account.
2.  **AWS CLI Configured:** Terraform uses your AWS CLI configuration for authentication. Your IAM user needs permissions to create EC2 instances, key pairs, security groups, CloudWatch alarms, and SNS topics.
3.  **Terraform Installed:** As per previous lessons.
4.  **SSH Key Pair:** You should have an SSH key pair ready (e.g., `~/.ssh/my_aws_key_sg.pub` and `~/.ssh/my_aws_key_sg`).

-----

### Step 1: Create a New Project Directory

Create a new directory for this project and navigate into it:

```bash
mkdir terraform-cloudwatch-alarm
cd terraform-cloudwatch-alarm
```

-----

### Step 2: Define the Terraform Configuration (`main.tf`)

Create a file named `main.tf` in your `terraform-cloudwatch-alarm` directory and add the following content.

```terraform
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
```

**Explanation of `main.tf`:**

  * **EC2 Setup:** Reuses simplified components from previous lessons to create a basic EC2 instance that we can monitor. It uses default VPC and subnets for simplicity.
  * **`aws_sns_topic "cpu_alarm_topic"`**: This resource creates a new SNS topic. This is a messaging channel that can send notifications to various endpoints (email, SMS, SQS, Lambda, etc.).
  * **`aws_sns_topic_subscription "email_subscription"`**: This resource subscribes an email address to the SNS topic. **Crucially, after `terraform apply`, you will receive an email from AWS asking you to confirm the subscription. You MUST click the confirmation link in that email for the alarm notifications to be delivered.**
  * **`aws_cloudwatch_metric_alarm "cpu_utilization_alarm"`**: This is the core alarm resource.
      * **`alarm_name`**: A unique name for your alarm.
      * **`comparison_operator = "GreaterThanOrEqualToThreshold"`**: The condition that triggers the alarm.
      * **`evaluation_periods = "1"`**: How many consecutive periods the threshold must be breached to trigger the alarm.
      * **`metric_name = "CPUUtilization"`** & **`namespace = "AWS/EC2"`**: Specifies the exact metric to monitor (EC2's CPU Utilization).
      * **`period = "300"`**: The period over which the statistic is applied (here, 300 seconds = 5 minutes).
      * **`statistic = "Average"`**: The statistic to apply to the metric data (e.g., Average, Sum, Maximum).
      * **`threshold = var.cpu_threshold_percent`**: The value that, when crossed, triggers the alarm. We'll set this to 80% via a variable.
      * **`dimensions`**: Used to filter the metric data. `InstanceId = aws_instance.monitored_ec2.id` ensures this alarm applies only to our specific EC2 instance.
      * **`alarm_actions = [aws_sns_topic.cpu_alarm_topic.arn]`**: This specifies what action to take when the alarm state changes to `ALARM`. Here, it publishes a message to our SNS topic. `ok_actions` and `insufficient_data_actions` are optional but good practice.
  * **Outputs:** Provides handy information like the EC2 public IP, SNS topic ARN, and alarm name.

-----

### Step 3: Define Variables (`variables.tf`)

Create a file named `variables.tf` in the same directory:

```terraform
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
```

-----

### Step 4: Provide Variable Values (`terraform.tfvars`)

Create a file named `terraform.tfvars` in your `terraform-cloudwatch-alarm` directory. **Update all placeholder values with your actual information.**

```terraform
# terraform.tfvars

aws_region                 = "us-east-1" # Or your desired region
project_name               = "MyMonitoringApp"

# Replace X.X.X.X with your actual public IP address (e.g., "203.0.113.45/32")
my_public_ip               = "X.X.X.X/32"

# Paths to your SSH key pair
key_pair_name              = "my-alarm-key-$(date +%s)" # Unique name for your key pair in AWS
public_key_path            = "/home/your_user/.ssh/my_aws_key_sg.pub" # <--- IMPORTANT: Update with your actual public key path
private_key_path           = "/home/your_user/.ssh/my_aws_key_sg"    # <--- IMPORTANT: Update with your actual private key path

# Your email address for notifications
notification_email_address = "your_email@example.com" # <--- IMPORTANT: Replace with your actual email
```

**How to find `my_public_ip`:**
Open your browser and search for "what is my ip". It will usually show your current public IP address. Append `/32` to it (e.g., if your IP is `203.0.113.45`, use `203.0.113.45/32`) as CIDR block notation.

-----

### Step 5: Run Terraform Commands

Navigate to your `terraform-cloudwatch-alarm/` directory.

#### `terraform init`

Initialize Terraform. This downloads the AWS provider.

```bash
terraform init
```

#### `terraform plan`

Review the execution plan. You should see plans to create an EC2 instance, security group, key pair, an SNS topic, an SNS subscription, and a CloudWatch alarm.

```bash
terraform plan
```

#### `terraform apply`

Execute the plan. Type `yes` when prompted.

```bash
terraform apply
```

After the apply completes, you will see the outputs:

```
...
Apply complete! Resources: X added, 0 changed, 0 destroyed.

Outputs:

cloudwatch_alarm_name = "MyMonitoringApp-EC2-CPU-High-Alarm"
ec2_public_ip = "X.X.X.X"
sns_topic_arn = "arn:aws:sns:us-east-1:XXXXXXXXXXXX:MyMonitoringApp-CPU-Alarm-Topic"
ssh_command = "ssh -i /home/your_user/.ssh/my_aws_key_sg ec2-user@X.X.X.X"
```

#### **IMPORTANT: Confirm SNS Subscription**

**Immediately after `terraform apply` finishes, check the email address you provided in `terraform.tfvars`. You will receive an email from AWS (Sender: `AWS Notifications <no-reply@sns.amazonaws.com>`) with the subject "AWS Notification - Subscription Confirmation". You MUST click the "Confirm subscription" link in this email.**

Until you confirm, your CloudWatch alarm will not be able to send notifications to your email address.

#### Test the CloudWatch Alarm (Optional)

To test the alarm, you need to deliberately increase the CPU utilization of your EC2 instance.

1.  **SSH into your EC2 instance:** Use the `ssh_command` output from Terraform.
    ```bash
    ssh -i /home/your_user/.ssh/my_aws_key_sg ec2-user@<YOUR_EC2_PUBLIC_IP>
    ```
2.  **Install a CPU stress tool (stress-ng):**
    ```bash
    sudo yum install -y stress-ng
    ```
3.  **Start stressing the CPU:**
    ```bash
    stress-ng --cpu 0 --timeout 600s # Stresses all CPUs for 10 minutes
    ```
    (You can open another SSH session to monitor `htop` if you like: `sudo yum install htop -y && htop`)
4.  **Monitor CloudWatch:**
      * Go to your AWS Console -\> CloudWatch -\> Alarms.
      * After a few minutes (depending on your `period` and `evaluation_periods`), you should see the `MyMonitoringApp-EC2-CPU-High-Alarm` change its state from `OK` to `IN ALARM`.
      * Once in `ALARM` state (and if you confirmed the SNS subscription), you should receive an email notification from AWS about the alarm.
5.  **Stop stressing the CPU:** Press `Ctrl+C` in the terminal where `stress-ng` is running. After a few more minutes, the alarm should return to `OK` state, and you might receive another email notification (if you configured `ok_actions`).

#### `terraform destroy`

When you're done testing, remember to destroy all resources to avoid unnecessary AWS costs.

```bash
terraform destroy
```

Type `yes` when prompted.

