# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy the S3 bucket in."
  type        = string
  default     = "us-east-1" # Or your preferred region, e.g., "ap-southeast-1" (Singapore)
}

variable "s3_bucket_name" {
  description = "The globally unique name for your S3 bucket."
  type        = string
}
