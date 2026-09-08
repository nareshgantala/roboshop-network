variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "subnet_id" {
  type = string
}

variable "sg_id" {
  type = string
}

variable "profile" {
  type = string
}

variable "project" {
  type = string
}

variable "env" {
  type = string
}

