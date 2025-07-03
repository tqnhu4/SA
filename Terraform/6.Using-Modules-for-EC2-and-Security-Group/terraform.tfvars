# terraform.tfvars (Root Variable Values)

aws_region        = "us-east-1"
key_pair_name     = "my-modules-key-$(date +%s)" # Unique name for your key pair in AWS
public_key_path   = "/home/your_user/.ssh/my_aws_key_sg.pub" # <--- IMPORTANT: Update with your actual public key path
private_key_path  = "/home/your_user/.ssh/my_aws_key_sg"    # <--- IMPORTANT: Update with your actual private key path
my_public_ip      = "X.X.X.X/32" # <--- IMPORTANT: Replace X.X.X.X with your actual public IP, e.g., "203.0.113.45/32"