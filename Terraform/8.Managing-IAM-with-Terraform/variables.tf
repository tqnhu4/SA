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