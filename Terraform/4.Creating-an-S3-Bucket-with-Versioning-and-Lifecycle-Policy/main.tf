# main.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create an S3 Bucket
resource "aws_s3_bucket" "my_versioned_bucket" {
  bucket = var.s3_bucket_name
  # You can uncomment and set ACL if needed, but AWS recommends bucket policies
  # acl    = "private"

  tags = {
    Name        = var.s3_bucket_name
    Environment = "Dev"
  }
}

# Enable Versioning for the S3 Bucket
resource "aws_s3_bucket_versioning" "my_versioned_bucket_versioning" {
  bucket = aws_s3_bucket.my_versioned_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Attach a Lifecycle Policy to the S3 Bucket
resource "aws_s3_bucket_lifecycle_configuration" "my_bucket_lifecycle" {
  bucket = aws_s3_bucket.my_versioned_bucket.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    # Apply to all objects in the bucket (no prefix specified)
    # This rule applies to noncurrent (previous) versions of objects

    noncurrent_version_expiration {
      noncurrent_days = 30 # Expire noncurrent versions after 30 days
    }

    # Optional: Transition current versions to Infrequent Access after 60 days
    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }

    # Optional: Expire current versions after 180 days (careful with this!)
    # expiration {
    #   days = 180
    # }
  }

  rule {
    id     = "move-to-glacier"
    status = "Enabled"
    filter {
      prefix = "archives/" # Apply this rule only to objects with the prefix "archives/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365 # Expire objects in 'archives/' after 1 year in Glacier
    }
  }
}

# Output the S3 Bucket Name and ARN
output "s3_bucket_name" {
  description = "The name of the created S3 bucket."
  value       = aws_s3_bucket.my_versioned_bucket.bucket
}

output "s3_bucket_arn" {
  description = "The ARN of the created S3 bucket."
  value       = aws_s3_bucket.my_versioned_bucket.arn
}
