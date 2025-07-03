-----

## Lesson 6: Using Modules for EC2 and Security Group

This project will teach you how to organize your Terraform configurations into reusable **modules**. Modules encapsulate a set of resources and allow you to deploy them multiple times with different parameters, promoting code reuse and consistency.

You'll learn about:

1.  **Creating a Local Module:** Structuring a directory as a Terraform module.
2.  **Defining Module Inputs (Variables):** Passing parameters into your modules.
3.  **Defining Module Outputs:** Exposing information from your modules.
4.  **Calling a Module:** Reusing the module in your root configuration.
5.  **Reusing Modules with Different Parameters:** Deploying multiple instances with varied configurations.

-----

### Project Structure

We'll organize our project with the following directory structure:

```
terraform-modules-ec2-sg/
├── main.tf              # Calls the modules
├── variables.tf         # Root variables
├── terraform.tfvars     # Root variable values
├── modules/
│   ├── ec2_instance/
│   │   ├── main.tf      # EC2 resource definitions
│   │   ├── variables.tf # EC2 module input variables
│   │   └── outputs.tf   # EC2 module outputs
│   └── security_group/
│       ├── main.tf      # Security Group resource definitions
│       ├── variables.tf # Security Group module input variables
│       └── outputs.tf   # Security Group module outputs
└── .gitignore
```

-----

### Prerequisites

Before you begin, ensure you have the following:

1.  **AWS Account:** An active AWS account.
2.  **AWS CLI Configured:** Terraform uses your AWS CLI configuration for authentication.
3.  **Terraform Installed:** As per previous lessons.
4.  **SSH Key Pair:** You should have an SSH key pair ready (e.g., `~/.ssh/my_aws_key_sg.pub` and `~/.ssh/my_aws_key_sg`).

-----

### Step 1: Set up the Project Directory Structure

Create the main project directory and the `modules` subdirectory:

```bash
mkdir terraform-modules-ec2-sg
cd terraform-modules-ec2-sg
mkdir modules
mkdir modules/ec2_instance
mkdir modules/security_group
```

-----

### Step 2: Define the `security_group` Module

Navigate into the `modules/security_group` directory:

```bash
cd modules/security_group
```

#### `modules/security_group/main.tf`

This file will contain the AWS Security Group resource definition.

```terraform
# modules/security_group/main.tf

resource "aws_security_group" "this" {
  name_prefix = var.name_prefix
  description = var.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      security_groups = ingress.value.security_groups
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      security_groups = egress.value.security_groups
    }
  }

  tags = var.tags
}
```

#### `modules/security_group/variables.tf`

This file defines the input variables for the `security_group` module.

```terraform
# modules/security_group/variables.tf

variable "name_prefix" {
  description = "A name prefix for the security group."
  type        = string
}

variable "description" {
  description = "Description of the security group."
  type        = string
  default     = "Managed by Terraform module"
}

variable "vpc_id" {
  description = "The ID of the VPC to create the security group in."
  type        = string
}

variable "ingress_rules" {
  description = "A list of ingress rules for the security group."
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = optional(list(string), [])
  }))
  default = []
}

variable "egress_rules" {
  description = "A list of egress rules for the security group."
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = optional(list(string), [])
  }))
  default = [{
    description     = "Allow all outbound traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = []
  }]
}

variable "tags" {
  description = "A map of tags to apply to the security group."
  type        = map(string)
  default     = {}
}
```

#### `modules/security_group/outputs.tf`

This file defines the output variables for the `security_group` module.

```terraform
# modules/security_group/outputs.tf

output "security_group_id" {
  description = "The ID of the created security group."
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "The ARN of the created security group."
  value       = aws_security_group.this.arn
}
```

-----

### Step 3: Define the `ec2_instance` Module

Navigate into the `modules/ec2_instance` directory (from `modules/security_group`, use `cd ../ec2_instance`).

#### `modules/ec2_instance/main.tf`

This file will contain the AWS EC2 instance resource definition.

```terraform
# modules/ec2_instance/main.tf

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

# Create an EC2 Instance
resource "aws_instance" "this" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id     = var.subnet_id # Optional: Use default if not specified

  user_data = var.user_data

  tags = var.tags
}
```

#### `modules/ec2_instance/variables.tf`

This file defines the input variables for the `ec2_instance` module.

```terraform
# modules/ec2_instance/variables.tf

variable "instance_name" {
  description = "The name tag for the EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the SSH key pair to associate with the instance."
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with the instance."
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the instance in. (Optional, AWS picks one in default VPC if not set)."
  type        = string
  default     = null # Use null to indicate it's optional
}

variable "user_data" {
  description = "User data to provide to the EC2 instance at launch."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to apply to the EC2 instance."
  type        = map(string)
  default     = {}
}
```

#### `modules/ec2_instance/outputs.tf`

This file defines the output variables for the `ec2_instance` module.

```terraform
# modules/ec2_instance/outputs.tf

output "instance_id" {
  description = "The ID of the EC2 instance."
  value       = aws_instance.this.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.this.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the EC2 instance."
  value       = aws_instance.this.private_ip
}
```

-----

### Step 4: Define Root Configuration (`main.tf`, `variables.tf`, `terraform.tfvars`)

Navigate back to the root of your project directory:

```bash
cd ../../ # from modules/ec2_instance
```

#### `main.tf` (Root Configuration)

This file will call our newly created modules.

```terraform
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
```

**Explanation of Root `main.tf`:**

  * **`data "aws_vpc" "default"`**: This data source automatically fetches the ID of your default VPC, which is convenient for simple setups.
  * **`resource "aws_key_pair" "my_key_pair"`**: Creates the SSH key pair in AWS, similar to previous lessons.
  * **`module "web_server_sg"`**: This block calls our `security_group` module.
      * **`source = "./modules/security_group"`**: Specifies the local path to our module.
      * We pass various parameters (`name_prefix`, `description`, `vpc_id`, `ingress_rules`, `tags`) to the module using its defined input variables.
      * **`ingress_rules`**: Notice how we're building a list of complex objects to pass to the module's `ingress_rules` variable. This allows the module to be highly flexible. We've included `var.my_public_ip` for SSH, which you'll define in `terraform.tfvars`.
  * **`module "web_server_01"`**: Calls the `ec2_instance` module for the first web server.
      * **`source = "./modules/ec2_instance"`**: Path to the `ec2_instance` module.
      * **`security_group_ids = [module.web_server_sg.security_group_id]`**: This is a key part of modularity. We're directly referencing the `security_group_id` output from our `web_server_sg` module. This creates a dependency, ensuring the security group is created before the EC2 instance.
      * **`user_data`**: Configures Nginx.
  * **`module "web_server_02"`**: Calls the `ec2_instance` module *again* for a second web server.
      * Notice `instance_type = "t2.small"`: We can easily change parameters for each instance of the module.
      * **`security_group_ids = [module.web_server_sg.security_group_id]`**: Reuses the *same* security group for both instances, demonstrating efficient management.
      * **`user_data`**: Configures Apache for variety.
  * **Outputs**: The root configuration's outputs reference the outputs from the called modules (e.g., `module.web_server_01.instance_public_ip`).

#### `variables.tf` (Root Variables)

Create this file in the root directory:

```terraform
# variables.tf (Root Variables)

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1" # Or your preferred region
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

variable "my_public_ip" {
  description = "Your local machine's public IP address for SSH access."
  type        = string
  # A placeholder. You'll put your actual IP in terraform.tfvars.
  # You can find your public IP by searching "what is my ip" on Google.
}
```

#### `terraform.tfvars` (Root Variable Values)

Create this file in the root directory. **Update `my_public_ip`, `public_key_path`, and `private_key_path` with your actual values.**

```terraform
# terraform.tfvars (Root Variable Values)

aws_region        = "us-east-1"
key_pair_name     = "my-modules-key-$(date +%s)" # Unique name for your key pair in AWS
public_key_path   = "/home/your_user/.ssh/my_aws_key_sg.pub" # <--- IMPORTANT: Update with your actual public key path
private_key_path  = "/home/your_user/.ssh/my_aws_key_sg"    # <--- IMPORTANT: Update with your actual private key path
my_public_ip      = "X.X.X.X/32" # <--- IMPORTANT: Replace X.X.X.X with your actual public IP, e.g., "203.0.113.45/32"
```

**How to find `my_public_ip`:**
Open your browser and search for "what is my ip". It will usually show your current public IP address. Append `/32` to it (e.g., if your IP is `203.0.113.45`, use `203.0.113.45/32`) as CIDR block notation.

-----

### Step 5: Run Terraform Commands

Navigate to the root directory `terraform-modules-ec2-sg/` if you're not already there.

#### `terraform init`

Initialize Terraform. This step is crucial for modules, as Terraform needs to discover and prepare them.

```bash
terraform init
```

You will see output indicating that Terraform is initializing the provider and *also* the local modules.

```
...
Initializing modules...
- module.ec2_instance
- module.security_group
...
Terraform has been successfully initialized!
```

#### `terraform plan`

Review the execution plan. You should see plans for one AWS Key Pair, one AWS Security Group (created by `module.web_server_sg`), and two AWS EC2 Instances (created by `module.web_server_01` and `module.web_server_02`).

```bash
terraform plan
```

Carefully inspect the output to understand what resources will be created.

#### `terraform apply`

Execute the plan. Type `yes` when prompted.

```bash
terraform apply
```

This will take several minutes as all resources are provisioned and user data scripts run.
Once complete, you will see the outputs for both web servers:

```
...
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

web_server_01_http_url = "http://X.X.X.X"
web_server_01_public_ip = "X.X.X.X"
web_server_01_ssh_command = "ssh -i /home/your_user/.ssh/my_aws_key_sg ec2-user@X.X.X.X"
web_server_02_http_url = "http://Y.Y.Y.Y"
web_server_02_public_ip = "Y.Y.Y.Y"
web_server_02_ssh_command = "ssh -i /home/your_user/.ssh/my_aws_key_sg ec2-user@Y.Y.Y.Y"
```

#### Test SSH and HTTP Access

1.  **SSH Access:** Use the provided SSH commands for both `web_server_01` and `web_server_02` to connect.

      * For `web_server_01`, verify Nginx: `sudo systemctl status nginx`
      * For `web_server_02`, verify Apache: `sudo systemctl status httpd`

2.  **HTTP Access:** Open your browser and visit the `http_url` for both web servers. You should see "Hello from Web Server 01\!" and "Hello from Web Server 02 (Apache)\!" respectively.

#### `terraform destroy`

When you're done testing, destroy all resources to avoid unnecessary costs.

```bash
terraform destroy
```

Type `yes` when prompted.

