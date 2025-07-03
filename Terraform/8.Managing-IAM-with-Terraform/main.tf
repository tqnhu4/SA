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