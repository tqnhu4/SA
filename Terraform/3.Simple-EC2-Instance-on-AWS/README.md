

## Lesson 3: Simple EC2 Instance on AWS

This project will guide you through deploying your first EC2 instance on Amazon Web Services (AWS) using Terraform. You'll learn about:

1.  **Declaring the AWS Provider and Region:** How to tell Terraform to interact with AWS.
2.  **Creating an EC2 Instance:** Provisioning a basic virtual machine.
3.  **Managing SSH Key Pairs:** Securely accessing your EC2 instance.
4.  **Using `terraform.tfvars`:** Providing sensitive or environment-specific variables.

-----

### Prerequisites

Before you begin, ensure you have the following:

1.  **AWS Account:** You need an active AWS account.
2.  **AWS CLI Configured:** Terraform uses your AWS CLI configuration for authentication. Make sure you have the AWS CLI installed and configured with appropriate credentials (e.g., via `aws configure`). Your IAM user needs permissions to create EC2 instances, key pairs, security groups, etc.
3.  **Terraform Installed:** As per previous lessons.

-----

### Step 1: Create a New Project Directory

Create a new directory for this project and navigate into it:

```bash
mkdir terraform-aws-ec2
cd terraform-aws-ec2
```

-----

### Step 2: Define AWS Provider and Region (`main.tf`)

Create a file named `main.tf` in your `terraform-aws-ec2` directory and add the following content. This file will declare the AWS provider and configure the region.

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
```

**Explanation of `main.tf`:**

  * **`provider "aws"`**: This block configures the AWS provider.
      * **`region = var.aws_region`**: Specifies the AWS region where resources will be deployed. We're using a variable here for flexibility.
  * **`data "aws_ami" "amazon_linux_2"`**: This is a "data source" block. It tells Terraform to query AWS for information rather than creating a resource. Here, we're finding the most recent Amazon Linux 2 AMI ID.
  * **`resource "aws_security_group" "ec2_sg"`**: Creates an AWS Security Group, which acts as a virtual firewall for your EC2 instance.
      * **`ingress`**: Defines inbound rules. We allow SSH (port 22) from `0.0.0.0/0` (any IP address). **For production, you should restrict this to known IP addresses.**
      * **`egress`**: Defines outbound rules. We allow all outbound traffic.
  * **`resource "aws_instance" "my_ec2_instance"`**: This is the core resource that creates the EC2 instance.
      * **`ami`**: The Amazon Machine Image ID. We use the ID obtained from our `data "aws_ami"` block.
      * **`instance_type`**: The size of the EC2 instance (e.g., `t2.micro` is eligible for AWS Free Tier).
      * **`key_name`**: The name of the SSH key pair that will be associated with the instance. This allows you to SSH into the instance later.
      * **`vpc_security_group_ids`**: Associates the security group we just created with the EC2 instance.
      * **`tags`**: Key-value pairs for organizing and identifying your AWS resources.
  * **`resource "aws_key_pair" "my_key_pair"`**: Creates an SSH key pair within AWS. Terraform expects the public key content.
      * **`key_name`**: The name you want to give to your key pair in AWS.
      * **`public_key = file(var.public_key_path)`**: Reads the content of your public key file from the path specified by the `public_key_path` variable.
  * **`output "instance_public_ip"`**: Displays the public IP address of the newly created EC2 instance after `terraform apply`.
  * **`output "ssh_command"`**: Provides a convenient SSH command string you can copy-paste to connect to your instance.

-----

### Step 3: Define Variables (`variables.tf`)

Create a file named `variables.tf` in the same directory to declare the input variables used in `main.tf`.

```terraform
# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1" # Or your preferred region like "ap-southeast-1" (Singapore) or "ap-southeast-2" (Sydney)
}

variable "aws_vpc_id" {
  description = "The ID of the VPC to deploy the EC2 instance into. (Use default for simplicity if unsure)."
  type        = string
  default     = "" # If empty, Terraform will try to find the default VPC.
                   # You can explicitly set it to your default VPC ID.
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

**Explanation of `variables.tf`:**

  * **`aws_region`**: Specifies the AWS region. It has a default, but you can override it.
  * **`aws_vpc_id`**: The ID of the Virtual Private Cloud (VPC) where the instance will be launched. For simplicity, we've set a default empty string which usually makes AWS use your default VPC. If you have multiple VPCs or a non-default setup, you'd specify a VPC ID here. You can find your default VPC ID in the AWS Console under VPC -\> Your VPCs.
  * **`key_pair_name`**: The name that your SSH key pair will have in the AWS console.
  * **`public_key_path`**: The local path to your SSH public key (`.pub` file). Terraform reads this file to upload the public key to AWS.
  * **`private_key_path`**: The local path to your SSH private key. This variable is only used in the `ssh_command` output for convenience; Terraform itself doesn't use your private key.

-----

### Step 4: Create/Locate Your SSH Key Pair

If you don't already have an SSH key pair, you can generate one using `ssh-keygen` on your local machine:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/my_aws_key
```

This command will create two files in your `~/.ssh/` directory:

  * `my_aws_key` (your private key)
  * `my_aws_key.pub` (your public key)

**Important:** Keep your private key (`my_aws_key`) secure and never share it. Set appropriate permissions: `chmod 400 ~/.ssh/my_aws_key`.

-----

### Step 5: Provide Variable Values (`terraform.tfvars`)

Create a file named `terraform.tfvars` in your `terraform-aws-ec2` directory. Terraform automatically loads variable values from this file. **This is the recommended place for sensitive information or environment-specific values that you don't want to hardcode in `main.tf`.**

Replace the placeholder paths with the actual paths to your public and private keys and choose a unique key pair name.

```terraform
# terraform.tfvars

aws_region        = "us-east-1" # Or your desired region, e.g., "ap-southeast-1"
aws_vpc_id        = ""          # Leave empty to use default VPC, or paste your VPC ID here
key_pair_name     = "my-ec2-key-pair-$(date +%s)" # A unique name for your key pair
public_key_path   = "/home/your_user/.ssh/my_aws_key.pub" # <--- IMPORTANT: Update with your actual public key path
private_key_path  = "/home/your_user/.ssh/my_aws_key"    # <--- IMPORTANT: Update with your actual private key path
```

**Note:**

  * Replace `/home/your_user/.ssh/my_aws_key.pub` and `/home/your_user/.ssh/my_aws_key` with the actual paths on your system.
  * `$(date +%s)` for `key_pair_name` generates a unique name based on the current timestamp. This is useful for testing to avoid name collisions if you create and destroy keys frequently. For production, you'd typically use a more static, descriptive name.

-----

### Step 6: Run Terraform Commands

Now you're ready to deploy your EC2 instance\!

#### `terraform init`

Initialize the Terraform working directory. This downloads the AWS provider plugin.

```bash
terraform init
```

You should see confirmation that Terraform has been successfully initialized.

#### `terraform plan`

Review the execution plan. Terraform will show you all the resources it intends to create (EC2 instance, security group, key pair).

```bash
terraform plan
```

Carefully review the output. It should show:

  * `+ resource "aws_key_pair" "my_key_pair"`
  * `+ resource "aws_security_group" "ec2_sg"`
  * `+ resource "aws_instance" "my_ec2_instance"`
  * The output values for `instance_public_ip` and `ssh_command` will be `(known after apply)`.

#### `terraform apply`

Execute the plan to create the resources in your AWS account.

```bash
terraform apply
```

Terraform will display the plan again and ask for confirmation. Type `yes` and press Enter.

Terraform will then proceed to create the resources. This might take a couple of minutes. Once complete, you will see the output values:

```
...
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

instance_public_ip = "X.X.X.X" # Your instance's public IP
ssh_command = "ssh -i /home/your_user/.ssh/my_aws_key ec2-user@X.X.X.X" # Your actual SSH command
```

#### `ssh` into your EC2 instance

Copy the `ssh_command` output value and paste it into your terminal. Remember to replace `X.X.X.X` with your instance's actual public IP.

```bash
ssh -i /home/your_user/.ssh/my_aws_key ec2-user@<YOUR_EC2_PUBLIC_IP>
```

You should now be connected to your Amazon Linux EC2 instance\!

#### `terraform destroy`

When you're done, destroy the resources to avoid incurring unnecessary AWS costs.

```bash
terraform destroy
```

Terraform will display the resources it plans to destroy. Type `yes` and press Enter to confirm.

```
...
Destroy complete! Resources: 3 destroyed.
```

