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