# vpc/variables.tf

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_tags" {
  description = "Tags for the VPC"
  type        = map(string)
}

variable "igw_tags" {
  description = "Tags for the IGW"
  type        = map(string)
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "environment for vpc"
}

variable "vpc_name" {
  description = "CIDR block for the VPC"
  type        = string
}
