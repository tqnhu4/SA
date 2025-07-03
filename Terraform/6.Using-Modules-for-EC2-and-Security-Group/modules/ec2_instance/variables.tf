# modules/ec2_instance/variables.tf

variable "instance_name" {
  description = "The name tag for the EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the SSH key pair to associate with the instance."
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with the instance."
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the instance in. (Optional, AWS picks one in default VPC if not set)."
  type        = string
  default     = null # Use null to indicate it's optional
}

variable "user_data" {
  description = "User data to provide to the EC2 instance at launch."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to apply to the EC2 instance."
  type        = map(string)
  default     = {}
}