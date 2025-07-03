# terraform.tfvars

aws_region        = "us-east-1" # Choose your desired region
project_name      = "My3TierApp"

# Replace X.X.X.X with your actual public IP address (e.g., "203.0.113.45/32")
my_public_ip      = "X.X.X.X/32"

# Paths to your SSH key pair
key_pair_name     = "my-3tier-app-key-$(date +%s)" # Unique name for your key pair in AWS
public_key_path   = "/home/your_user/.ssh/my_aws_key_sg.pub" # <--- IMPORTANT: Update with your actual public key path
private_key_path  = "/home/your_user/.ssh/my_aws_key_sg"    # <--- IMPORTANT: Update with your actual private key path

# RDS Database Credentials (CHANGE THESE!)
rds_username      = "admin"
rds_password      = "MySuperStrongPassword123!" # <--- IMPORTANT: Use a strong, unique password