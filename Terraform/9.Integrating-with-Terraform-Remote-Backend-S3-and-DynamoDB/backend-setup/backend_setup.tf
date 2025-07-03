# backend-setup/backend_setup.tf

provider "aws" {
  region = var.aws_region
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private" # Best practice: Keep your state private

  # Enable versioning to keep a history of your state file
  versioning {
    enabled = true
  }

  # Enable server-side encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "Terraform-Remote-State"
    Environment = "Backend"
  }
}

# DynamoDB Table for Terraform State Locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST" # Or "PROVISIONED" with read/write capacity
  hash_key       = "LockID"          # Required for state locking

  attribute {
    name = "LockID"
    type = "S" # String type
  }

  tags = {
    Name        = "Terraform-State-Lock"
    Environment = "Backend"
  }
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket created for Terraform state."
  value       = aws_s3_bucket.terraform_state_bucket.bucket
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table created for state locking."
  value       = aws_dynamodb_table.terraform_state_lock.name
}