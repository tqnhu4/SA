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