# backend-setup/variables.tf

variable "aws_region" {
  description = "The AWS region for backend resources."
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "A globally unique name for your S3 bucket."
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name for the DynamoDB table."
  type        = string
}