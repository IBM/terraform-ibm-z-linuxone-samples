output "httpd_instances" {
  description = "Full instance details"
  value       = module.zvm_httpd_guests
}

output "haproxy_instances" {
  description = "Full instance details"
  value       = module.zvm_haproxy_guests
}

