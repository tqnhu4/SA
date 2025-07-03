# terraform.tfvars

aws_region        = "us-east-1" # Or your desired region
aws_vpc_id        = ""          # Leave empty to use default VPC, or paste your VPC ID here
key_pair_name     = "my-ec2-sg-key-$(date +%s)" # Unique name for your key pair in AWS
public_key_path   = "/home/your_user/.ssh/my_aws_key_sg.pub" # <--- IMPORTANT: Update with your actual public key path
private_key_path  = "/home/your_user/.ssh/my_aws_key_sg"    # <--- IMPORTANT: Update with your actual private key path
