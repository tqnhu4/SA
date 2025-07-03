# my-remote-app/main.tf

# Configure the Terraform Backend to use S3 and DynamoDB
terraform {
  backend "s3" {
    bucket         = "my-unique-terraform-state-bucket-XXXXXXXXXX" # REPLACE with your S3 bucket name
    key            = "dev/my-app.tfstate"                           # Path within the bucket
    region         = "us-east-1"                                    # REPLACE with your AWS region
    dynamodb_table = "my-unique-terraform-state-lock"               # REPLACE with your DynamoDB table name
    encrypt        = true                                           # Ensure state is encrypted at rest
  }
}

# Configure the AWS Provider for the resources you're deploying
provider "aws" {
  region = var.aws_region
}

# Example Resource: A Null Resource to demonstrate state management
resource "null_resource" "my_remote_resource" {
  triggers = {
    timestamp = timestamp()
    greeting  = var.greeting_message
  }

  provisioner "local-exec" {
    command = "echo '${var.greeting_message}'"
  }
}

output "resource_id" {
  description = "ID of the null resource."
  value       = null_resource.my_remote_resource.id
}

output "final_greeting" {
  description = "The greeting message used."
  value       = var.greeting_message
}