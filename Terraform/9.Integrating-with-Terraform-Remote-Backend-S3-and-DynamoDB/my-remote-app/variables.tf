# my-remote-app/variables.tf

variable "aws_region" {
  description = "The AWS region for deploying application resources."
  type        = string
  default     = "us-east-1"
}

variable "greeting_message" {
  description = "A message to be printed by the null resource."
  type        = string
  default     = "Hello, Terraform Remote Backend!"
}