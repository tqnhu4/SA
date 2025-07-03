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