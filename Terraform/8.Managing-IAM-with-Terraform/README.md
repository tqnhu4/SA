
-----

## Lesson 8: Managing IAM with Terraform

This project will guide you through using Terraform to automate the creation and management of AWS IAM resources. IAM is fundamental for controlling access to your AWS resources, and managing it with Infrastructure as Code ensures consistency, auditability, and scalability.

You'll learn about:

1.  **IAM User:** Creating individual IAM users.
2.  **IAM Group:** Grouping users and attaching policies to the group.
3.  **IAM Policy:** Defining permissions and attaching them to users or groups.
4.  **IAM Role for EC2:** Creating a service role that an EC2 instance can assume to gain permissions.
5.  **Instance Profile:** Associating an IAM role with an EC2 instance.

-----

### Architecture Overview

  * **IAM User + Group + Policy:** Create an IAM user, add them to a group, and attach an AWS managed policy (e.g., `ReadOnlyAccess`) to the group.
  * **IAM Role for EC2:** Create a role that an EC2 instance can assume. Attach a policy (e.g., `AmazonS3ReadOnlyAccess`) to this role, allowing the EC2 instance to perform actions on S3 without needing explicit credentials.

-----

### Prerequisites

Before you begin, ensure you have the following:

1.  **AWS Account:** An active AWS account.
2.  **AWS CLI Configured:** Terraform uses your AWS CLI configuration for authentication. Your IAM user needs permissions to create IAM users, groups, policies, roles, and instance profiles.
3.  **Terraform Installed:** As per previous lessons.

-----

### Step 1: Create a New Project Directory

Create a new directory for this project and navigate into it:

```bash
mkdir terraform-iam-management
cd terraform-iam-management
```

-----

### Step 2: Define the Terraform Configuration (`main.tf`)

Create a file named `main.tf` in your `terraform-iam-management` directory and add the following content.

```terraform
# main.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# --- IAM User, Group, and Policy Management ---

# 1. Create an IAM User
resource "aws_iam_user" "dev_user" {
  name          = var.iam_user_name
  path          = "/devops/"
  force_destroy = true # Allows deletion of user even if they have active access keys, etc. (USE WITH CAUTION IN PROD)

  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

# 2. Create an IAM Group
resource "aws_iam_group" "devops_group" {
  name = var.iam_group_name

  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

# 3. Add the User to the Group
resource "aws_iam_group_membership" "dev_user_membership" {
  user   = aws_iam_user.dev_user.name
  group  = aws_iam_group.devops_group.name
}

# 4. Attach an AWS Managed Policy to the Group (e.g., ReadOnlyAccess)
resource "aws_iam_group_policy_attachment" "devops_read_only_access" {
  group      = aws_iam_group.devops_group.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess" # AWS Managed Policy
}

# Optional: Create a custom IAM policy and attach it
resource "aws_iam_policy" "custom_s3_read_policy" {
  name        = "${var.project_prefix}-S3ReadAccess"
  description = "Allows read-only access to S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = "*" # Allows access to all S3 buckets. Restrict in production!
      },
    ],
  })

  tags = {
    ManagedBy = "Terraform"
  }
}

# Optional: Attach custom policy to the group
resource "aws_iam_group_policy_attachment" "devops_custom_s3_read_access" {
  group      = aws_iam_group.devops_group.name
  policy_arn = aws_iam_policy.custom_s3_read_policy.arn
}


# --- IAM Role for EC2 ---

# 1. Create an IAM Role for EC2
resource "aws_iam_role" "ec2_s3_reader_role" {
  name = "${var.project_prefix}-EC2S3ReaderRole"

  # The 'assume role policy' allows EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })

  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
    Purpose     = "EC2S3Reader"
  }
}

# 2. Attach an AWS Managed Policy to the Role (e.g., AmazonS3ReadOnlyAccess)
resource "aws_iam_role_policy_attachment" "s3_read_access_for_ec2" {
  role       = aws_iam_role.ec2_s3_reader_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" # AWS Managed Policy
}

# 3. Create an Instance Profile (to attach the role to an EC2 instance)
resource "aws_iam_instance_profile" "ec2_s3_reader_profile" {
  name = "${var.project_prefix}-EC2S3ReaderProfile"
  role = aws_iam_role.ec2_s3_reader_role.name

  tags = {
    ManagedBy = "Terraform"
  }
}

# --- Outputs ---

output "iam_user_name" {
  description = "The name of the IAM user created."
  value       = aws_iam_user.dev_user.name
}

output "iam_group_name" {
  description = "The name of the IAM group created."
  value       = aws_iam_group.devops_group.name
}

output "ec2_iam_role_name" {
  description = "The name of the IAM role for EC2 instances."
  value       = aws_iam_role.ec2_s3_reader_role.name
}

output "ec2_instance_profile_name" {
  description = "The name of the IAM instance profile for EC2."
  value       = aws_iam_instance_profile.ec2_s3_reader_profile.name
}
```

**Explanation of `main.tf`:**

  * **`provider "aws"`**: Configures the AWS provider.
  * **IAM User, Group, and Policy:**
      * **`aws_iam_user "dev_user"`**: Creates an IAM user. `force_destroy = true` is used here for convenience in a learning environment, allowing the user to be deleted even if it has access keys or other attached resources. **Be extremely cautious with `force_destroy` in production environments.**
      * **`aws_iam_group "devops_group"`**: Creates an IAM group.
      * **`aws_iam_group_membership "dev_user_membership"`**: Adds the `dev_user` to the `devops_group`.
      * **`aws_iam_group_policy_attachment "devops_read_only_access"`**: Attaches an AWS managed policy (`ReadOnlyAccess`) to the `devops_group`. AWS managed policies are predefined by AWS.
      * **`aws_iam_policy "custom_s3_read_policy"`**: Demonstrates creating a *custom* IAM policy. The `policy` argument uses `jsonencode` to define the policy document in HCL. This specific policy allows read access to S3.
      * **`aws_iam_group_policy_attachment "devops_custom_s3_read_access"`**: Attaches the *custom* S3 read policy to the `devops_group`.
  * **IAM Role for EC2:**
      * **`aws_iam_role "ec2_s3_reader_role"`**: Creates an IAM role.
          * **`assume_role_policy`**: This is a crucial part. It defines who (or what AWS service) is allowed to *assume* this role. In this case, `Service = "ec2.amazonaws.com"` means the EC2 service can assume this role.
      * **`aws_iam_role_policy_attachment "s3_read_access_for_ec2"`**: Attaches an AWS managed policy (`AmazonS3ReadOnlyAccess`) to the `ec2_s3_reader_role`. Once an EC2 instance assumes this role, it will inherit these permissions.
      * **`aws_iam_instance_profile "ec2_s3_reader_profile"`**: An Instance Profile is a container for an IAM role that you can use to pass role information to an EC2 instance. EC2 instances cannot directly assume roles; they assume an instance profile, which in turn refers to the role.
  * **Outputs:** Provides the names of the created IAM user, group, role, and instance profile for verification.

-----

### Step 3: Define Variables (`variables.tf`)

Create a file named `variables.tf` in the same directory:

```terraform
# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy IAM resources in (IAM is global, but region is often specified)."
  type        = string
  default     = "us-east-1" # IAM is a global service, but a region is still needed for provider config.
}

variable "project_prefix" {
  description = "A prefix for naming IAM resources to ensure uniqueness and organization."
  type        = string
  default     = "MyIAMApp"
}

variable "iam_user_name" {
  description = "The name for the IAM user."
  type        = string
}

variable "iam_group_name" {
  description = "The name for the IAM group."
  type        = string
}
```

-----

### Step 4: Provide Variable Values (`terraform.tfvars`)

Create a file named `terraform.tfvars` in your `terraform-iam-management` directory.

```terraform
# terraform.tfvars

aws_region     = "us-east-1"
project_prefix = "MyTerraformIAM" # Ensure this is unique if you run multiple times
iam_user_name  = "dev-user-01"
iam_group_name = "DevOpsTeam"
```

-----

### Step 5: Run Terraform Commands

Navigate to your `terraform-iam-management/` directory.

#### `terraform init`

Initialize Terraform.

```bash
terraform init
```

#### `terraform plan`

Review the execution plan. You should see plans to create one IAM user, one IAM group, one group membership, and several policy attachments, an IAM role, and an instance profile.

```bash
terraform plan
```

#### `terraform apply`

Execute the plan to create the IAM resources in your AWS account.

```bash
terraform apply
```

Terraform will display the plan again and ask for confirmation. Type `yes` and press Enter.

Once complete, you will see the outputs:

```
...
Apply complete! Resources: 7 added, 0 changed, 0 destroyed. # (Count may vary based on optional policies)

Outputs:

ec2_iam_role_name = "MyTerraformIAM-EC2S3ReaderRole"
ec2_instance_profile_name = "MyTerraformIAM-EC2S3ReaderProfile"
iam_group_name = "DevOpsTeam"
iam_user_name = "dev-user-01"
```

#### Verification (Optional - AWS Console)

You can log into your AWS Management Console and navigate to the IAM service:

  * **Users:** You should see `dev-user-01`.
  * **Groups:** You should see `DevOpsTeam`. Click on it to confirm `dev-user-01` is a member and that `ReadOnlyAccess` (and your custom S3 policy) is attached.
  * **Roles:** You should see `MyTerraformIAM-EC2S3ReaderRole`. Click on it to see its trust policy (allowing `ec2.amazonaws.com` to assume it) and attached policies (e.g., `AmazonS3ReadOnlyAccess`).
  * **Instance Profiles:** You should see `MyTerraformIAM-EC2S3ReaderProfile` linked to the role.

#### `terraform destroy`

When you're done, destroy the resources.

```bash
terraform destroy
```

Type `yes` when prompted.

