-----

Here's how to write your second Terraform application, focusing on **variables (input variables)** and **outputs**. You'll create a simple configuration that takes a name as input and outputs a personalized greeting.

-----

## Lesson 2: Variables and Outputs in Terraform

This exercise will teach you how to define input variables to make your Terraform configurations more flexible and how to use outputs to display important information after an `apply`.

-----

### Step 1: Create a New Project Directory

First, create a new directory for this project and navigate into it. It's good practice to keep each Terraform configuration in its own separate directory.

```bash
mkdir terraform-variables
cd terraform-variables
```

-----

### Step 2: Define Variables in `variables.tf`

In Terraform, it's common practice to define your input variables in a separate file, typically named `variables.tf`. Create this file in your `terraform-variables` directory and add the following content:

```terraform
# variables.tf

variable "user_name" {
  description = "The name of the user to greet."
  type        = string
  default     = "World" # Optional: A default value if not provided
}

variable "greeting_prefix" {
  description = "The prefix for the greeting (e.g., 'Hello', 'Hi')."
  type        = string
  default     = "Hello"
}
```

Let's break down these variable declarations:

  * **`variable "user_name"`**: This block declares an input variable named `user_name`.
      * **`description`**: A human-readable description of what the variable is for. This is very helpful for others (and your future self\!) understanding your configuration.
      * **`type`**: Specifies the data type of the variable. Common types include `string`, `number`, `bool`, `list`, `map`, and `object`. Here, we use `string`.
      * **`default`**: An optional value that Terraform will use if no explicit value is provided for this variable. If you omit `default`, Terraform will prompt you for a value during `plan` or `apply` if one isn't supplied via other methods (like command-line arguments or `.tfvars` files).
  * **`variable "greeting_prefix"`**: Another variable for the greeting, also with a default.

-----

### Step 3: Use Variables and Define Outputs in `main.tf`

Now, create your `main.tf` file in the same `terraform-variables` directory. This file will use the variables you just defined and create an output that displays the greeting.

```terraform
# main.tf

resource "null_resource" "greet_user" {
  # This resource doesn't manage infrastructure, but it allows us to
  # demonstrate using variables and outputs locally.
  provisioner "local-exec" {
    command = "echo '${var.greeting_prefix}, ${var.user_name}!'"
  }

  triggers = {
    # This trigger ensures the local-exec runs every time we apply
    # if any variable it depends on changes.
    user_name_changed = var.user_name
    prefix_changed    = var.greeting_prefix
  }
}

output "full_greeting_message" {
  description = "The complete greeting message."
  value       = "${var.greeting_prefix}, ${var.user_name}!"
}

output "user_name_used" {
  description = "The user name that was used in the greeting."
  value       = var.user_name
}
```

Here's what's happening in `main.tf`:

  * **`resource "null_resource" "greet_user"`**: We're using a `null_resource` again, primarily to run a local command for demonstration purposes.
      * **` command = "echo '${var.greeting_prefix}, ${var.user_name}!'"  `**: This is where you use your variables\! `var.user_name` and `var.greeting_prefix` reference the values of the variables you declared. Terraform interpolates these values into the string.
      * **`triggers`**: We've set triggers to `var.user_name` and `var.greeting_prefix`. This means if either of these input variables changes, the `null_resource` (and its `local-exec` provisioner) will be marked for recreation during the next `apply`.
  * **`output "full_greeting_message"`**: This block defines an output value.
      * **`description`**: A description for the output.
      * **`value`**: The actual value to be displayed. Again, we're using string interpolation with our variables to create the full greeting message.
  * **`output "user_name_used"`**: A second output to demonstrate displaying just the `user_name` that was used.

-----

### Step 4: Run Terraform Commands with Variables

Now, let's run the Terraform commands and see how variables and outputs work.

#### `terraform init`

Initialize your new Terraform working directory:

```bash
terraform init
```

This will download the `null` provider.

#### `terraform plan` (with default values)

First, let's run a plan without providing any variable values. Terraform will use the `default` values you defined in `variables.tf`.

```bash
terraform plan
```

You should see output indicating that Terraform plans to create one `null_resource` and the output values will show "Hello, World\!".

```
...
Plan: 1 to add, 0 to change, 0 to destroy.

Outputs:

full_greeting_message = "Hello, World!"
user_name_used = "World"
```

#### `terraform apply` (with default values)

Apply the configuration using the default values:

```bash
terraform apply
```

Type `yes` when prompted. You'll see the `local-exec` provisioner print "Hello, World\!" and then the output values.

```
...
null_resource.greet_user (local-exec): Hello, World!
...
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

full_greeting_message = "Hello, World!"
user_name_used = "World"
```

#### `terraform apply` (overriding variables)

Now, let's override the `user_name` variable directly from the command line.

```bash
terraform apply -var="user_name=Alice"
```

Type `yes` when prompted. Notice how the `local-exec` output and the final Terraform outputs now reflect "Alice":

```
...
null_resource.greet_user (local-exec): Hello, Alice!
...
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

full_greeting_message = "Hello, Alice!"
user_name_used = "Alice"
```

You can also override multiple variables:

```bash
terraform apply -var="user_name=Bob" -var="greeting_prefix=Hi"
```

Again, type `yes`.

```
...
null_resource.greet_user (local-exec): Hi, Bob!
...
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

full_greeting_message = "Hi, Bob!"
user_name_used = "Bob"
```

#### `terraform destroy`

Finally, clean up the resources created by your configuration:

```bash
terraform destroy
```

Type `yes` when prompted.

