---
## Roadmap to Learning Intermediate Terraform

This roadmap builds upon the foundational knowledge and guides you through more advanced concepts and best practices for building robust and reusable infrastructure with Terraform.

### Intermediate Level: Building Robust and Reusable Infrastructure

This level focuses on best practices, modularity, and managing more complex infrastructure efficiently.

* 📦 **Terraform Modules:**
    * **Understand the concept of Terraform modules for reusability and organization.**
        * **Example:** Instead of defining an EC2 instance, security group, and elastic IP in one monolithic file, you can create a "web_app" module that encapsulates all these related resources. This promotes the DRY (Don't Repeat Yourself) principle.
    * **Create and consume local modules.**
        * **Example (Local Module Structure):**
            ```
            .
            ├── main.tf             # Root configuration file
            ├── variables.tf        # Root input variables
            ├── outputs.tf          # Root outputs
            └── modules/
                └── web_server/     # Your custom module directory
                    ├── main.tf
                    ├── variables.tf
                    └── outputs.tf
            ```
        * **Example (Calling a Local Module from `main.tf`):**
            ```terraform
            # main.tf (in your root directory)
            module "my_web_app_instance" {
              source        = "./modules/web_server" # Relative path to your module
              instance_type = "t3.small"
              ami_id        = "ami-053b0d53c279acc90" # Example AMI for Amazon Linux 2 (Virginia)
              key_name      = "your-ssh-key-pair"    # Replace with your actual key pair name
              # Add other module-specific variables here
            }

            output "web_app_public_ip" {
              description = "Public IP of the web server from the module."
              value       = module.my_web_app_instance.public_ip # Accessing output from the module
            }
            ```
    * **Explore the Terraform Registry for publicly available modules.**
        * **Example:** Using a pre-built AWS VPC module from the registry:
            ```terraform
            # main.tf
            module "vpc" {
              source = "terraform-aws-modules/vpc/aws"
              version = "3.18.0" # Always pin module versions for consistency

              name = "my-prod-vpc"
              cidr = "10.0.0.0/16"

              azs             = ["us-east-1a", "us-east-1b"]
              private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
              public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

              enable_nat_gateway = true
              single_nat_gateway = true
              enable_vpn_gateway = false

              tags = {
                Environment = "production"
              }
            }
            ```
    * **Hands-on Project:** Refactor your previous simple web server deployment into a reusable module. Create separate `main.tf`, `variables.tf`, and `outputs.tf` files inside a `modules/web_server` directory, and then call this module from your root `main.tf`.

* ☁️ **Remote State Management:**
    * **Learn about remote backends (e.g., S3, Azure Blob Storage, GCP Cloud Storage) for storing state in a shared, versioned, and secure location.**
        * **Example (AWS S3 Backend in `main.tf`):**
            ```terraform
            terraform {
              backend "s3" {
                bucket         = "my-terraform-state-bucket-unique-12345" # Replace with your unique S3 bucket name
                key            = "environments/dev/my-app/terraform.tfstate" # Path to your state file
                region         = "us-east-1"
                dynamodb_table = "terraform-lock-table"                       # Optional: for state locking
                encrypt        = true                                       # Encrypts the state file at rest
              }
            }
            ```
            **Note:** You need to create the S3 bucket and DynamoDB table (if used for locking) manually or with a separate Terraform configuration before using this backend.
    * **Understand state locking for collaborative environments.**
        * **Example:** DynamoDB is often used with S3 for state locking. When one user runs `terraform apply`, a lock is acquired on the state file. If another user tries to run `apply` simultaneously, they will be blocked until the lock is released, preventing concurrent modifications and state corruption.

* 🔍 **Data Sources:**
    * **Utilize data sources to fetch information about existing infrastructure or external data that is not managed by your current Terraform configuration.**
        * **Example (Get information about a specific Amazon Machine Image - AMI):**
            ```terraform
            data "aws_ami" "ubuntu_focal" {
              most_recent = true
              filter {
                name   = "name"
                values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
              }
              filter {
                name   = "virtualization-type"
                values = ["hvm"]
              }
              owners = ["099720109477"] # Canonical's AWS account ID
            }

            resource "aws_instance" "web_server_ubuntu" {
              ami           = data.aws_ami.ubuntu_focal.id # Use the ID from the data source
              instance_type = "t2.micro"
              key_name      = "your-ssh-key-pair"
              # ... other configuration
            }
            ```
    * **Hands-on Project:** Use a data source to retrieve details of an existing VPC (Virtual Private Cloud) by its name or ID, and then deploy a new resource (e.g., an EC2 instance or an RDS database) into a subnet within that VPC.

* ⚙️ **Provisioners (Local-exec, Remote-exec):**
    * **Understand when and how to use provisioners for bootstrapping or executing commands on resources after they are created or destroyed. (Note: Often better to use configuration management tools like Ansible, Chef, Puppet, or cloud-native user data for long-term configuration management).**
        * **`local-exec` Example (Run a script on the machine where Terraform is executed after instance creation):**
            ```terraform
            resource "aws_instance" "example_server" {
              ami           = "ami-053b0d53c279acc90"
              instance_type = "t2.micro"
              key_name      = "your-key-pair"

              provisioner "local-exec" {
                command = "echo 'AWS Instance ${self.id} was created at $(date)' >> instance_creation_log.txt"
              }
            }
            ```
        * **`remote-exec` Example (Run a command on the remote instance after creation, requires SSH access):**
            ```terraform
            resource "aws_instance" "remote_exec_server" {
              ami           = "ami-053b0d53c279acc90"
              instance_type = "t2.micro"
              key_name      = "your-key-pair"
              # ... security group allowing SSH ...

              provisioner "remote-exec" {
                inline = [
                  "sudo apt update -y",
                  "sudo apt install -y nginx",
                  "echo 'Hello from remote-exec!' | sudo tee /var/www/html/index.html",
                  "sudo systemctl start nginx"
                ]

                connection {
                  type        = "ssh"
                  user        = "ec2-user" # Or 'ubuntu', 'admin', etc., depending on AMI
                  private_key = file("~/.ssh/your-key-pair.pem")
                  host        = self.public_ip
                }
              }
            }
            ```

* ➕ **Functions and Expressions:**
    * **Explore built-in Terraform functions (e.g., `lookup`, `concat`, `length`, `cidrhost`, `split`, `join`).**
        * **Example (Using `concat` to combine lists):**
            ```terraform
            locals {
              list_of_dev_ips  = ["192.168.1.1", "192.168.1.2"]
              list_of_prod_ips = ["10.0.0.1", "10.0.0.2"]
              all_allowed_ips  = concat(local.list_of_dev_ips, local.list_of_prod_ips)
              # Result: ["192.168.1.1", "192.168.1.2", "10.0.0.1", "10.0.0.2"]
            }

            resource "aws_security_group" "app_sg" {
              # ...
              ingress {
                from_port   = 80
                to_port     = 80
                protocol    = "tcp"
                cidr_blocks = local.all_allowed_ips
              }
            }
            ```
        * **Example (Using `cidrhost` to get a specific IP from a CIDR block):**
            ```terraform
            resource "aws_network_interface" "management_nic" {
              subnet_id       = aws_subnet.private_subnet.id
              private_ips     = [cidrhost("10.0.1.0/24", 5)] # Assigns 10.0.1.5
              # ...
            }
            ```
    * **Understand expressions for dynamic value generation.**
        * **Example:** `"${var.environment}-web-server"` creates resource names like "dev-web-server", "staging-web-server", or "prod-web-server" based on an `environment` variable.

* 🔁 **Conditional Expressions and Loops (`for_each`, `count`):**
    * **Implement conditional logic in your configurations to create or omit resources based on certain conditions.**
        * **Example (Conditional resource creation):**
            ```terraform
            variable "enable_logging_bucket" {
              description = "Set to true to create a dedicated logging bucket."
              type        = bool
              default     = false
            }

            resource "aws_s3_bucket" "log_bucket" {
              count  = var.enable_logging_bucket ? 1 : 0 # Only create if enable_logging_bucket is true
              bucket = "my-app-logs-${var.environment}"
              acl    = "log-delivery-write"
              # ...
            }
            ```
    * **Use `count` to create multiple, identical instances of a resource.**
        * **Example (`count` for scaling identical web servers):**
            ```terraform
            variable "num_web_servers" {
              description = "Number of web servers to deploy."
              type        = number
              default     = 2
            }

            resource "aws_instance" "web_server_array" {
              count         = var.num_web_servers # Creates instances: aws_instance.web_server_array[0], [1], etc.
              ami           = "ami-053b0d53c279acc90"
              instance_type = "t2.micro"
              key_name      = "your-key-pair"
              tags = {
                Name = "web-server-${count.index}" # Tags will be "web-server-0", "web-server-1"
              }
              # ... other configuration
            }
            ```
    * **Use `for_each` to create multiple instances of a resource based on a map or set, allowing for unique configurations per instance.**
        * **Example (`for_each` for deploying specific database instances):**
            ```terraform
            variable "database_configs" {
              type = map(object({
                engine_version = string
                instance_type  = string
                allocated_storage = number
              }))
              default = {
                "web_db" = {
                  engine_version = "5.7.mysql"
                  instance_type  = "db.t3.micro"
                  allocated_storage = 20
                },
                "reporting_db" = {
                  engine_version = "9.6.postgres"
                  instance_type  = "db.t3.small"
                  allocated_storage = 50
                }
              }
            }

            resource "aws_db_instance" "app_databases" {
              for_each             = var.database_configs # Iterate over the map keys (web_db, reporting_db)
              engine               = split(".", each.value.engine_version)[1] # Extract 'mysql' or 'postgres'
              engine_version       = each.value.engine_version
              instance_class       = each.value.instance_type
              allocated_storage    = each.value.allocated_storage
              identifier           = "app-${each.key}" # Identifier will be 'app-web_db', 'app-reporting_db'
              username             = "${each.key}_user"
              password             = "Password123!" # In real-world, use Secrets Manager!
              skip_final_snapshot  = true
              # ... other configuration
            }
            ```
    * **Hands-on Project:** Deploy multiple identical web servers using `count` OR deploy multiple, slightly different database instances using `for_each` based on a variable map.

* 🗂️ **Terraform Workspaces:**
    * **Understand how to use workspaces for managing multiple environments (dev, staging, prod) within a single Terraform configuration. Workspaces provide separate state files for each environment.**
        * **Example:**
            ```bash
            # Create a new workspace for development
            terraform workspace new dev

            # Select the 'dev' workspace
            terraform workspace select dev

            # Apply changes to the 'dev' environment
            terraform apply

            # Create a new workspace for production
            terraform workspace new prod

            # Select the 'prod' workspace
            terraform workspace select prod

            # Apply changes to the 'prod' environment
            terraform apply
            ```
            You can then use `terraform.workspace` in your configuration to adjust resource names or settings based on the selected workspace (e.g., `"${terraform.workspace}-my-bucket"`).

* 📦 **Introduction to Terragrunt (Optional but Recommended):**
    * **Explore Terragrunt as a thin wrapper around Terraform. It helps manage multiple Terraform root modules, enforce DRY (Don't Repeat Yourself) principles, handle remote state and inputs more effectively, and promotes a consistent folder structure for large projects.**
        * **Example (Simple Terragrunt `terragrunt.hcl` configuration):**
            ```hcl
            # live/dev/us-east-1/webserver/terragrunt.hcl
            include {
              path = find_in_parent_folders() # Inherit common settings from parent folders
            }

            terraform {
              source = "../../_modules/webserver" # Relative path to your reusable Terraform module

              # Automatically configure S3 backend for this specific deployment
              remote_state {
                backend = "s3"
                config = {
                  bucket         = "my-shared-terraform-states"
                  key            = "dev/us-east-1/webserver/terraform.tfstate"
                  region         = "us-east-1"
                  dynamodb_table = "terraform-lock-table"
                  encrypt        = true
                }
              }
            }

            inputs = {
              # Pass inputs to the webserver module
              instance_type = "t2.micro"
              ami_id        = "ami-053b0d53c279acc90"
              environment   = "dev"
            }
            ```
            Running `terragrunt apply` in this `webserver` directory will fetch the module, configure the remote state, and apply it with the specified inputs. This helps avoid repeating backend and common variable definitions across many Terraform configurations.

---

### General Tips for Intermediate Learning:

* 🧑‍💻 **Practice Modular Design:** Always think about how you can break down your infrastructure into reusable modules. This is crucial for maintainability and scalability.
* 🌐 **Master Data Sources:** Understanding data sources empowers you to interact with existing infrastructure and external services, making your configurations more dynamic.
* 📚 **Deep Dive into Functions:** Explore the full range of Terraform's built-in functions. They are incredibly powerful for transforming data and making your configurations more flexible.
* 🛠️ **Understand `count` vs. `for_each`:** These are fundamental for deploying multiple resources. Spend time understanding their differences and when to use each.
* 🤝 **Experiment with Remote State:** Set up an S3 bucket (or equivalent) for remote state early on, even for personal projects, to get comfortable with it.
* 💬 **Engage with the Community:** Join Terraform Slack channels, forums, or attend meetups. Learning from others' experiences is invaluable.

By mastering these intermediate concepts, you'll be able to design and deploy more sophisticated, organized, and robust infrastructure with Terraform. Good luck!