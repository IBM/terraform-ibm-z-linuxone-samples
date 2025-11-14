provider "openstack" {
  # Configuration options
  user_name   = "YOUR_ICIC_ID"
  tenant_name = "YOUR_ICIC_TENANT"   # Default is "ibm-default"
  password    = var.openstack_password
  auth_url    = "https://YOUR_ICIC_URL/icic/openstack/identity/v3"
  domain_name = "YOUR_ICIC_DOMAIN"   # Default is "Default"
  insecure    = true                 # e.g. if ICIC uses self-signed TLS cert
}
