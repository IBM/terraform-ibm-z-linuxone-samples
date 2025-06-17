variable "ode_host" {
    type        = string
    description = "ODE API host"
}

variable "ode_username" {
    type        = string
    description = "ODE API username"
}

variable "ode_password" {
    type        = string
    description = "ODE API password"
    sensitive   = true
}
variable "ssh_target_key_file" {
    type        = string
    description = "Target ssh key file"
    sensitive   = false
}

####################################### Stock Image Variables #######################################

variable "image_uuid" {
     type        = string
     description = "UUID of the image to look up"
 }

variable "image_label" {
    type        = string
    description = "Image label (name) to filter on"
    default     = "IBM Stock image (1.0.2)"
}

variable "image_version" {
    type        = number
    description = "z/OS stock image version"
    default     = 1
}

####################################### Instance Variables #######################################

# variable "ssh_target_key_file" {
#     description = "Path to private key (if using key-based auth)."
#     type        = string
#     sensitive   = true
# }

variable "ssh_target_user" {
    description = "Linux SSH username."
    type        = string
}

variable "ssh_target_password" {
    description = "Linux SSH password (if using password auth)."
    type        = string
    sensitive   = true
}

# General block
variable "instance_label" {
    description = "Label for the instance."
    type        = string
    default     = "terraformz-dev-z-instnace"
}

variable "instance_description" {
    description = "Optional instance description."
    type        = string
    default     = "Terraform-zOS-Dev-Instance"
}

// When running without target dep
variable "target_uuid" {
     description = "UUID of the target environment."
     type        = string
 }

variable "ssh_public_key" {
    description = "Public SSH key for the Linux user (optional)."
    type        = string
}

variable "deployment_directory" {
    description = "Path on the target where ODE deploys the instance."
    type        = string
    default     = "/opt"
}

// When running without image dep
variable "sysres_component_uuid" {
     description = "UUID of the SYSRES component."
     type        = string
 }

# Emulator block
variable "cp" {
    description = "Number of CP engines."
    type        = number
}

variable "ziip" {
    description = "Number of zIIP engines."
    type        = number
    default     = 0
}

variable "ram" {
    description = "RAM in bytes (5 GiB = 5368709120)."
    type        = number
    default     = 8589934592
}