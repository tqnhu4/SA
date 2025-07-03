

## Lesson 5: Creating a Custom Security Group and Using it with EC2

This project builds upon our previous EC2 example by:

1.  **Defining a Custom Security Group:** Explicitly creating a security group with specific inbound rules.
2.  **Allowing SSH (Port 22) and HTTP (Port 80):** Configuring the security group to permit access on these common ports.
3.  **Attaching to an EC2 Instance:** Associating the custom security group with our EC2 instance.

-----

### Prerequisites

Before you begin, ensure you have the following:

1.  **AWS Account:** An active AWS account.
2.  **AWS CLI Configured:** Terraform uses your AWS CLI configuration for authentication. Your IAM user needs permissions to create EC2 instances, key pairs, and security groups.
3.  **Terraform Installed:** As per previous lessons.

-----

### Step 1: Create a New Project Directory

Create a new directory for this project and navigate into it:

```bash
mkdir terraform-ec2-custom-sg
cd terraform-ec2-custom-sg
```

-----

### Step 2: Define AWS Provider, EC2 Instance, Key Pair, and Custom Security Group (`main.tf`)

Create a file named `main.tf` in your `terraform-ec2-custom-sg` directory and add the following content:

```terraform
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
```

**Key Changes and Explanations in `main.tf`:**

  * **`resource "aws_security_group" "custom_ec2_sg"`**:
      * We define a new security group named `custom_ec2_sg`.
      * **`ingress` blocks:** Two `ingress` blocks are defined:
          * One for `from_port = 22` and `to_port = 22` (SSH).
          * Another for `from_port = 80` and `to_port = 80` (HTTP).
          * Both allow access from `0.0.0.0/0` for simplicity in this example. **Remember to restrict this in production\!**
  * **`vpc_security_group_ids = [aws_security_group.custom_ec2_sg.id]`**: In the `aws_instance` resource, we now explicitly reference the ID of our newly created `custom_ec2_sg` to attach it to the EC2 instance.
  * **`user_data`**: This block uses a "heredoc" syntax (`<<-EOF ... EOF`) to provide a shell script that will run when the EC2 instance first launches.
      * It updates packages, installs Nginx (a web server), starts it, enables it to start on boot, and then creates a simple `index.html` file. This allows us to test port 80 accessibility.
  * **`output "http_url"`**: A new output that provides the direct URL to access the Nginx web server.

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

variable "aws_vpc_id" {
  description = "The ID of the VPC to deploy the EC2 instance into. (Use default for simplicity if unsure)."
  type        = string
  default     = "" # If empty, Terraform will try to find the default VPC.
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
```

These variables are largely the same as in Lesson 3.

-----

### Step 4: Create/Locate Your SSH Key Pair

If you don't already have an SSH key pair, generate one:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/my_aws_key_sg
```

This creates `~/.ssh/my_aws_key_sg` (private) and `~/.ssh/my_aws_key_sg.pub` (public).
Remember to set permissions: `chmod 400 ~/.ssh/my_aws_key_sg`.

-----

### Step 5: Provide Variable Values (`terraform.tfvars`)

Create a file named `terraform.tfvars` in your `terraform-ec2-custom-sg` directory. Replace the placeholder paths with your actual key paths.

```terraform
# terraform.tfvars

aws_region        = "us-east-1" # Or your desired region
aws_vpc_id        = ""          # Leave empty to use default VPC, or paste your VPC ID here
key_pair_name     = "my-ec2-sg-key-$(date +%s)" # Unique name for your key pair in AWS
public_key_path   = "/home/your_user/.ssh/my_aws_key_sg.pub" # <--- IMPORTANT: Update with your actual public key path
private_key_path  = "/home/your_user/.ssh/my_aws_key_sg"    # <--- IMPORTANT: Update with your actual private key path
```

**Note:** Ensure `public_key_path` and `private_key_path` point to the correct files for your generated key.

-----

### Step 6: Run Terraform Commands

Time to deploy and test\!

#### `terraform init`

Initialize the Terraform working directory.

```bash
terraform init
```

#### `terraform plan`

Review the execution plan. You should see plans for one `aws_key_pair`, one `aws_security_group`, and one `aws_instance`.

```bash
terraform plan
```

#### `terraform apply`

Execute the plan. Type `yes` when prompted.

```bash
terraform apply
```

This will take a few minutes as the EC2 instance launches and the `user_data` script runs to install Nginx.
Once complete, you will see the outputs:

```
...
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

http_url = "http://X.X.X.X" # Your instance's public IP
instance_public_ip = "X.X.X.X" # Your instance's public IP
ssh_command = "ssh -i /home/your_user/.ssh/my_aws_key_sg ec2-user@X.X.X.X" # Your SSH command
```

#### Test SSH and HTTP Access

1.  **SSH Access:** Copy the `ssh_command` output and paste it into your terminal. You should be able to connect to your EC2 instance.

    ```bash
    ssh -i /home/your_user/.ssh/my_aws_key_sg ec2-user@<YOUR_EC2_PUBLIC_IP>
    ```

    Once connected, you can verify Nginx is running: `sudo systemctl status nginx`

2.  **HTTP Access:** Open a web browser and navigate to the `http_url` provided in the outputs. You should see the "Hello from your EC2 instance\!" message.

#### `terraform destroy`

When you're done testing, remember to destroy the resources to avoid incurring unnecessary AWS costs.

```bash
terraform destroy
```

Type `yes` when prompted.

