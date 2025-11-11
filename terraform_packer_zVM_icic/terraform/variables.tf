## Variables file

# Set a version indication, if you don't want most-recent when you create VMs
# If you want this: in main.tf (for each module) you will need to change from 
#   name_regex = 
#   most_recent = true 
# to
#   name = "YOUR_BASE_IMAGE_{haproxy|httpd}_$image_timestamp"
# and remove most_recent or set it explicitly to "most_recent = false".
# Also, this will set the version for both HAProxy and HTTPD VMs.  If you want different,
# override using the currently-empty variable in the module variables.tf file.
# If you use the supplied Packer config to create the images, the timestamp will be created
# at build-time and inserted into the names of both images.
#
variable "image_timestamp" {
  description = "Timestamp of the images"
  type        = string
  default     = "2025-06-07_02-35-12"
}

variable "openstack_password" {
  description = "OpenStack password"
  type        = string
}

# Variable to define the map of HTTPD VMs.
# The module will create a VM for each map item.
#
variable "httpd_guests" {
  description = "Definitions of the Apache VMs needed"
  type = map(any)

  default = {
    vm1 = {
      name = "httpd-1"
    },
    vm2 = {
      name = "httpd-2"
    },
    vm3 = {
      name = "httpd-3"
    }
  }
}

# Variable to define the map of HAProxy VMs.
# The module will create a VM for each map item.
# Note: I have not tested creating more than one HAProxy VM.
#       At the very least you would need to change the static IP address
#       assignment process.
#
variable "haproxy_guests" {
  description = "Definitions of the HAProxy VMs needed"
  type = map(any)

  default = {
    vm1 = {
      name = "haproxy-1"
    }
  }
}

