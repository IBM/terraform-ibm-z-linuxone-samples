provider "ode" {
  ode_host     = var.ode_host
  ode_username = var.ode_username
  ode_password = var.ode_password
  ode_tls = {
    ca_file     = file("/path/to/ca_file")
    server_name = "your-ode-server-name-matching-ca-certificate"
  }
}

data "ode_image" "zos_image" {
  flatten = true
  filter = {
    label   = var.image_label
    version = var.image_version
  }
}

resource "ode_instance" "demo_zos_env" {
  ssh_target_user     = var.ssh_target_user
  ssh_target_password = var.ssh_target_password

  general = {
    label                  = var.instance_label
    description            = var.instance_description
    ssh_public_key         = var.ssh_public_key
    deployment_directory   = var.deployment_directory
    target_uuid            = var.target_uuid
    image_uuid             = data.ode_image.zos_image.uuid
    sysres_component_uuid  = data.ode_image.zos_image.sysres_component_uuid
  }

  emulator = {
    cp  = var.cp
    ram = var.ram
  }
}

output "hostname" {
  value = ode_instance.demo_zos_env.hostname
}