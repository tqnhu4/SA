# backend-setup/terraform.tfvars

aws_region        = "us-east-1" # Or your desired region
s3_bucket_name    = "my-unique-terraform-state-bucket-$(date +%s)" # Replace with a truly unique name
dynamodb_table_name = "my-unique-terraform-state-lock" # Replace with a truly unique name
