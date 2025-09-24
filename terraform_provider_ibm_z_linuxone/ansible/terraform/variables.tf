variable "ibm_z_linuxone_host" {
    type        = string
    description = "z API host"
    default = "your-hmc-hostname"
}

variable "ibm_z_linuxone_username" {
    type        = string
    description = "z API username"
    default = ""

}

variable "ibm_z_linuxone_password" {
    type        = string
    description = "z API password"
    sensitive   = true
    default = ""
}