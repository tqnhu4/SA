# modules/security_group/variables.tf

variable "name_prefix" {
  description = "A name prefix for the security group."
  type        = string
}

variable "description" {
  description = "Description of the security group."
  type        = string
  default     = "Managed by Terraform module"
}

variable "vpc_id" {
  description = "The ID of the VPC to create the security group in."
  type        = string
}

variable "ingress_rules" {
  description = "A list of ingress rules for the security group."
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = optional(list(string), [])
  }))
  default = []
}

variable "egress_rules" {
  description = "A list of egress rules for the security group."
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = optional(list(string), [])
  }))
  default = [{
    description     = "Allow all outbound traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = []
  }]
}

variable "tags" {
  description = "A map of tags to apply to the security group."
  type        = map(string)
  default     = {}
}