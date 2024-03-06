variable "backend_ports_open" {
  description = "port to open from main variable.tf file"
}

variable "frontend_ports_open" {
  description = "port to open from main variable.tf file"
}

variable "vpc_id" {
  description = "VPC id from vpc-prod module"
}

variable "env" {
  description = "Value from vpc-prod module"
}

# variable "vpc_cidr" {
#   description = "CIDR block from vpc-prod module"
# }

variable "project_name" {
  description = "Name of the project"
}

variable "rds_ports_open" {}

variable "redis_ports_open" {}

variable "tags" {
  type = map(string)
  default = {}
}