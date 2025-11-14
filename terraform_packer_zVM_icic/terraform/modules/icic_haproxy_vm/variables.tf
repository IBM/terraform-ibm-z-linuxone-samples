## Variables file

variable "image_timestamp" {}

variable "name" {
  description = "Name of the VM"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "instance_purpose" {
  description = "Purpose of the instance (e.g. web, app, db)"
  type        = string
  default     = "demo"
}

variable "project" {
  description = "Project identifier"
  type        = string
  default     = "prj"
}

variable "availability_zone" {
  type		= string
  default = "Default Group"
}

variable "password" {
  type    = string
  default = "YOUR_SSH_PASSWORD"
}

variable "ip_address" {
  type    = string
  default = "YOUR_HAPROXY_STATIC_IP_ADDRESS"
}
