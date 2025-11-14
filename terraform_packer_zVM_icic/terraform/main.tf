
module "zvm_httpd_guests" {
  source = "./modules/icic_httpd_vm"
  for_each = var.httpd_guests

  name = each.value.name
  image_timestamp = var.image_timestamp
  depends_on = [module.zvm_haproxy_guests.haproxy_instances]
}


module "zvm_haproxy_guests" {
  source = "./modules/icic_haproxy_vm"
  for_each = var.haproxy_guests

  name = each.value.name
  image_timestamp = var.image_timestamp
}

# resource "null_resource" "haproxy_config" {
#   depends_on = [module.zvm_httpd_guests.httpd_instances, module.zvm_haproxy_guests.haproxy_instances]
#   provisioner "local-exec" {
#     command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.zvm_haproxy_guests.vm1.ip_address},' -u root --private-key ~/.ssh/id_ed25519 --extra-vars \"$(terraform output -json)\" ansible/playbook.yml"
#   }
# }
