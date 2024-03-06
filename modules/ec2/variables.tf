variable "instance_type" {
  description = "value from main variable.tf"
}

variable "backend_sg_id" {
  description = "value from module aws_sg"
}

variable "frontend_sg_id" {
  description = "value from module aws_sg"
}

variable "public_subnet_ids" {
  description = "public subnet ids from aws_net module"
}

variable "private_subnet_ids" {
  description = "private subnet ids from aws_net module"
}

variable "env" {
  description = "env variable"
}

variable "count_backend" {
  description = "count instances for backend"
}

variable "count_frontend" {
  description = "count instances for frontend"
}

variable "project_name" {
  description = "Name of the project"
}

variable "key_pair_name" {
  description = "Key pair name to get access to instance"
}

variable "tags" {
  type = map(string)
  default = {}
}