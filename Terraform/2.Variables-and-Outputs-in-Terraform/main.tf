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
