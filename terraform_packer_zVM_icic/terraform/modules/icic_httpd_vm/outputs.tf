output "vm_name" {
  description = "The name of the OpenStack instance created"
  value       = var.name
}

output "network_name" {
  description = "The name of the OpenStack network"
  value       = data.openstack_networking_network_v2.network.name
}

output "openstack_flavour_id" {
  description = "The ID of the OpenStack flavour"
  value       = data.openstack_compute_flavor_v2.size.id
}

output "openstack_image_id" {
  description = "The ID of the OpenStack image"
  value       = data.openstack_images_image_v2.img.id
}

output "ip_address" {
  description = "The IP address OpenStack assigned to the instance"
  value       = openstack_compute_instance_v2.zvm_instance.access_ip_v4
}
