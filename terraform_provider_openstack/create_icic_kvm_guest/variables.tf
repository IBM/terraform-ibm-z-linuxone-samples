# this is a file for defining the types of vars
variable "openstack_user_name" {
  description = "Username for authentication with ICIC"
  type        = string
  sensitive   = true
}
variable "openstack_password" {
  description = "Password for authentication with ICIC"
  type        = string
  sensitive   = true
}
variable "openstack_tenant_name" {
  description = "ICIC project name. It is expected that this project already exists."
  type        = string
}
variable "openstack_auth_url" {
  description = "URL for ICIC Auth API"
  type        = string
}
variable "openstack_cacert_file" {
  description = "Path to file containing CA certificate used by ICIC API"
  type        = string
}
variable "ssh_pub_key" {
  description = "SSH public key to add to the new guest"
  type        = string
}
variable "availability_zone" {
  description = "ICIC availability zone name where guest should be deployed"
  type        = string
}
variable "openstack_network_name" {
  description = "Name of a preconfigured network used by the guest on ICIC"
  type        = string
}
variable "guest_ip" {
  description = "IP address the guest will use"
  type        = string
}
variable "os_image" {
  description = "URL where the qcow to be used is available. It will be uploaded to glance"
  type        = string
}

variable "ip_allow_cidr" {
  description = "CIDR for IP addresses allowed to ping or SSH to the guest"
  type        = string
}