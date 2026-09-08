
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
}

variable "project" {
  type        = string
  description = "name of the project"
  default     = "roboshop"
}

variable "env" {
  type        = string
  description = "Environment"
}
