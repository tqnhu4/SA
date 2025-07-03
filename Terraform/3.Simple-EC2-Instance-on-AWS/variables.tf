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
