

## Lesson 4: Creating an S3 Bucket with Versioning and Lifecycle Policy

This project will guide you through deploying an S3 bucket on Amazon Web Services (AWS) with two important features: **Versioning** for data protection and a **Lifecycle Policy** for cost optimization and data management.

You'll learn about:

1.  **Declaring an S3 Bucket:** How to create a storage bucket.
2.  **Enabling Versioning:** Protecting your objects from accidental deletion or overwrites.
3.  **Attaching a Lifecycle Policy:** Automatically transitioning or expiring objects.

-----

### Prerequisites

Before you begin, ensure you have the following:

1.  **AWS Account:** An active AWS account.
2.  **AWS CLI Configured:** Terraform uses your AWS CLI configuration for authentication. Ensure your IAM user has permissions to create S3 buckets and manage bucket policies.
3.  **Terraform Installed:** As per previous lessons.

-----

### Step 1: Create a New Project Directory

Create a new directory for this project and navigate into it:

```bash
mkdir terraform-s3-bucket
cd terraform-s3-bucket
```

-----

### Step 2: Define AWS Provider, S3 Bucket, and Lifecycle Policy (`main.tf`)

Create a file named `main.tf` in your `terraform-s3-bucket` directory and add the following content:

```terraform
# main.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create an S3 Bucket
resource "aws_s3_bucket" "my_versioned_bucket" {
  bucket = var.s3_bucket_name
  # You can uncomment and set ACL if needed, but AWS recommends bucket policies
  # acl    = "private"

  tags = {
    Name        = var.s3_bucket_name
    Environment = "Dev"
  }
}

# Enable Versioning for the S3 Bucket
resource "aws_s3_bucket_versioning" "my_versioned_bucket_versioning" {
  bucket = aws_s3_bucket.my_versioned_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Attach a Lifecycle Policy to the S3 Bucket
resource "aws_s3_bucket_lifecycle_configuration" "my_bucket_lifecycle" {
  bucket = aws_s3_bucket.my_versioned_bucket.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    # Apply to all objects in the bucket (no prefix specified)
    # This rule applies to noncurrent (previous) versions of objects

    noncurrent_version_expiration {
      noncurrent_days = 30 # Expire noncurrent versions after 30 days
    }

    # Optional: Transition current versions to Infrequent Access after 60 days
    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }

    # Optional: Expire current versions after 180 days (careful with this!)
    # expiration {
    #   days = 180
    # }
  }

  rule {
    id     = "move-to-glacier"
    status = "Enabled"
    filter {
      prefix = "archives/" # Apply this rule only to objects with the prefix "archives/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365 # Expire objects in 'archives/' after 1 year in Glacier
    }
  }
}

# Output the S3 Bucket Name and ARN
output "s3_bucket_name" {
  description = "The name of the created S3 bucket."
  value       = aws_s3_bucket.my_versioned_bucket.bucket
}

output "s3_bucket_arn" {
  description = "The ARN of the created S3 bucket."
  value       = aws_s3_bucket.my_versioned_bucket.arn
}
```

**Explanation of `main.tf`:**

  * **`provider "aws"`**: Configures the AWS provider using a variable for the region.
  * **`resource "aws_s3_bucket" "my_versioned_bucket"`**: Creates the S3 bucket.
      * **`bucket = var.s3_bucket_name`**: Sets the bucket name using a variable. S3 bucket names must be globally unique across all AWS accounts.
      * **`tags`**: Applies tags for organization.
  * **`resource "aws_s3_bucket_versioning" "my_versioned_bucket_versioning"`**: This resource explicitly enables versioning for the bucket.
      * **`bucket = aws_s3_bucket.my_versioned_bucket.id`**: References the ID of the S3 bucket created previously.
      * **`status = "Enabled"`**: Turns on versioning.
  * **`resource "aws_s3_bucket_lifecycle_configuration" "my_bucket_lifecycle"`**: Attaches a lifecycle configuration to the bucket.
      * **`rule`**: Defines individual lifecycle rules. You can have multiple rules.
          * **`id`**: A unique identifier for the rule.
          * **`status = "Enabled"`**: Activates the rule.
          * **`noncurrent_version_expiration { noncurrent_days = 30 }`**: This rule is crucial when versioning is enabled. It means that any previous (noncurrent) versions of an object will be permanently deleted after 30 days.
          * **`transition`**: Defines actions to transition objects to different storage classes.
              * The first `transition` moves **current versions** of objects to `STANDARD_IA` (Infrequent Access) after 60 days. This is a common cost-saving strategy for data that's accessed less frequently.
          * **`filter { prefix = "archives/" }`**: For the second rule, we use a `filter` to apply this rule only to objects whose keys start with `archives/`. This is useful for managing different types of data within the same bucket.
          * The second `transition` moves objects within the `archives/` prefix to `GLACIER` after 90 days.
          * The second `expiration` rule ensures objects in `archives/` are *permanently deleted* after 365 days of creation (once they are in Glacier).
  * **`output "s3_bucket_name"`** and **`output "s3_bucket_arn"`**: These outputs will display the name and Amazon Resource Name (ARN) of your new S3 bucket after deployment.

-----

### Step 3: Define Variables (`variables.tf`)

Create a file named `variables.tf` in the same directory to declare the input variables.

```terraform
# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy the S3 bucket in."
  type        = string
  default     = "us-east-1" # Or your preferred region, e.g., "ap-southeast-1" (Singapore)
}

variable "s3_bucket_name" {
  description = "The globally unique name for your S3 bucket."
  type        = string
}
```

**Explanation of `variables.tf`:**

  * **`aws_region`**: Standard region variable with a default.
  * **`s3_bucket_name`**: The name of your S3 bucket. This **must be globally unique** across all AWS accounts. It's best to append a random string or timestamp to ensure uniqueness for testing.

-----

### Step 4: Provide Variable Values (`terraform.tfvars`)

Create a file named `terraform.tfvars` in your `terraform-s3-bucket` directory.

```terraform
# terraform.tfvars

aws_region     = "us-east-1" # Or your desired region
s3_bucket_name = "my-unique-versioned-bucket-$(date +%s)" # IMPORTANT: Change this to a truly unique name
```

**Note:**

  * Replace `$(date +%s)` with a unique identifier if you're not on a Unix-like system, or simply use a name like `my-company-project-data-bucket-12345` that you are confident is unique.
  * The `date +%s` command outputs the current Unix timestamp, which helps in generating unique bucket names for quick testing/learning scenarios.

-----

### Step 5: Run Terraform Commands

Now, let's deploy your S3 bucket\!

#### `terraform init`

Initialize the Terraform working directory to download the AWS provider plugin.

```bash
terraform init
```

#### `terraform plan`

Review the execution plan. Terraform will show you that it intends to create one `aws_s3_bucket`, one `aws_s3_bucket_versioning`, and one `aws_s3_bucket_lifecycle_configuration`.

```bash
terraform plan
```

Carefully inspect the plan to ensure it matches your expectations.

#### `terraform apply`

Execute the plan to create the S3 bucket in your AWS account.

```bash
terraform apply
```

Terraform will display the plan again and ask for confirmation. Type `yes` and press Enter.

Once complete, you will see the output values:

```
...
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

s3_bucket_arn = "arn:aws:s3:::my-unique-versioned-bucket-XXXXXXXXXX" # Your bucket's ARN
s3_bucket_name = "my-unique-versioned-bucket-XXXXXXXXXX" # Your bucket's name
```

You can now log into your AWS Management Console, navigate to the S3 service, and confirm that your bucket has been created with versioning enabled and the lifecycle rules applied.

#### `terraform destroy`

When you're done, destroy the resources to avoid incurring unnecessary AWS costs.

```bash
terraform destroy
```

Terraform will display the resources it plans to destroy. Type `yes` and press Enter to confirm.

```
...
Destroy complete! Resources: 3 destroyed.
```
