
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

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "jenkins_instance_type" {
  type        = string
  description = "EC2 instance type for Jenkins Controller"
  default     = "t3.small"
}

variable "bastion_instance_type" {
  type        = string
  description = "EC2 instance type for Bastion / Jenkins Worker node (Docker + KinD + Scans)"
  default     = "t3.medium"
}

variable "sonarqube_instance_type" {
  type        = string
  description = "EC2 instance type for SonarQube server"
  default     = "t3.medium"
}
