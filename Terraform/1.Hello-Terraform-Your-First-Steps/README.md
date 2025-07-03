

## Hello Terraform: Your First Steps

This guide will walk you through installing Terraform and creating your first `main.tf` file, using a `null_resource` to demonstrate basic Terraform commands.

-----

### Step 1: Install Terraform

First, you need to install Terraform on your system. The installation process varies depending on your operating system.

**For macOS (using Homebrew):**

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**For Windows (using Chocolatey):**

```bash
choco install terraform
```

**For Linux (Debian/Ubuntu):**

````bash
```bash
# Add the HashiCorp GPG key
curl -fsSL [https://apt.releases.hashicorp.com/gpg](https://apt.releases.hashicorp.com/gpg) | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add the HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] [https://apt.releases.hashicorp.com](https://apt.releases.hashicorp.com) $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update package list and install Terraform
sudo apt update
sudo apt install terraform
````

**For Linux (CentOS/RHEL):**

```bash
# Install yum-utils
sudo yum install -y yum-utils

# Add the HashiCorp repository
sudo yum-config-manager --add-repo [https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo](https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo)

# Install Terraform
sudo yum -y install terraform
```

After installation, verify it by running:

```bash
terraform -v
```

This command should output the installed Terraform version.

-----

### Step 2: Create Your First `main.tf` File

Create a new directory for your Terraform project and navigate into it:

```bash
mkdir hello-terraform
cd hello-terraform
```

Now, create a file named `main.tf` inside this directory and add the following content:

```terraform
# main.tf

resource "null_resource" "hello_world" {
  provisioner "local-exec" {
    command = "echo 'Hello from Terraform!'"
  }

  triggers = {
    always_run = timestamp()
  }
}

output "message" {
  value = "The 'hello_world' null_resource has been applied."
}
```

Let's break down this `main.tf` file:

  * **`resource "null_resource" "hello_world"`**: This declares a resource block.
      * `null_resource` is a special resource provided by Terraform that doesn't manage any external infrastructure. It's useful for running local scripts or as a placeholder.
      * `hello_world` is the local name you're giving to this specific instance of the `null_resource`.
  * **`provisioner "local-exec"`**: This block defines a "provisioner," which executes a local command on the machine running Terraform.
      * `command = "echo 'Hello from Terraform!'"`: This is the command that will be executed when the `null_resource` is created or updated. It simply prints "Hello from Terraform\!" to your console.
  * **`triggers = { always_run = timestamp() }`**: This ensures the `local-exec` provisioner runs every time you apply the configuration. Without a trigger, the `null_resource` might not execute the `local-exec` command again if its configuration hasn't explicitly changed. `timestamp()` generates a new timestamp every time, forcing a change.
  * **`output "message"`**: This defines an output variable that will display a message after Terraform successfully applies the configuration.

-----

### Step 3: Run Terraform Commands

Now you'll use the core Terraform commands to initialize, plan, apply, and destroy your configuration.

#### `terraform init`

This command initializes a Terraform working directory. It downloads necessary plugins (in this case, the `null` provider) and sets up the backend for state management.

Run in your `hello-terraform` directory:

```bash
terraform init
```

You should see output indicating that Terraform has been successfully initialized and the `null` provider has been installed.

#### `terraform plan`

The `terraform plan` command creates an execution plan. Terraform compares the desired state defined in your `main.tf` with the current state (which is empty right now) and shows you what actions it will take to reach the desired state. It **does not** make any changes to your infrastructure.

Run:

```bash
terraform plan
```

You'll see output similar to this, indicating that Terraform plans to add one `null_resource`:

```
Terraform will perform the following actions:

  # null_resource.hello_world will be created
  + resource "null_resource" "hello_world" {
      + id       = (known after apply)
      + triggers = {
          + "always_run" = (known after apply)
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

#### `terraform apply`

This command applies the changes required to reach the desired state of the configuration. It will prompt you for confirmation before making any changes.

Run:

```bash
terraform apply
```

Terraform will show you the plan again and then prompt you to confirm by typing `yes`. Type `yes` and press Enter.

You will see the output of your `echo` command: "Hello from Terraform\!", and then the output message you defined:

```
null_resource.hello_world: Creating...
null_resource.hello_world: Provisioning with 'local-exec'...
null_resource.hello_world (local-exec): Executing: ["/bin/sh" "-c" "echo 'Hello from Terraform!'"]
null_resource.hello_world (local-exec): Hello from Terraform!
null_resource.hello_world: Creation complete after 0s [id=...]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

message = "The 'hello_world' null_resource has been applied."
```

#### `terraform destroy`

The `terraform destroy` command is used to destroy the Terraform-managed infrastructure. It will remove all resources defined in your configuration.

Run:

```bash
terraform destroy
```

Terraform will show you what it plans to destroy and prompt you for confirmation. Type `yes` and press Enter.

You will see output similar to this, indicating the destruction of your `null_resource`:

```
null_resource.hello_world: Destroying...
null_resource.hello_world: Destruction complete after 0s

Destroy complete! Resources: 1 destroyed.
```

