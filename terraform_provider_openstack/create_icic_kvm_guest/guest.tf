# Define required providers
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name           = var.openstack_user_name
  tenant_name         = var.openstack_tenant_name
  password            = var.openstack_password
  auth_url            = var.openstack_auth_url
  region              = "RegionOne"
  project_domain_name = "Default"
  cacert_file         = var.openstack_cacert_file
}

# get the project 
data "openstack_identity_project_v3" "project" {
  name = var.openstack_tenant_name
}

# get the network ID for guests desired network
data "openstack_networking_network_v2" "network" {
  name = var.openstack_network_name
}


# create a port on the desired network
resource "openstack_networking_port_v2" "port_1" {
  name           = "test_port"
  network_id     = data.openstack_networking_network_v2.network.id
  admin_state_up = "true"

  fixed_ip {
    subnet_id  = data.openstack_networking_network_v2.network.subnets[0]
    ip_address = var.guest_ip
  }
}

# upload the iso image to glance?
resource "openstack_images_image_v2" "rhel9_2" {
  name             = "rhel-9.2"
  image_source_url = var.os_image
  container_format = "bare"
  disk_format      = "qcow2"

  properties = {
    arch = "s390x"
  }
}

resource "openstack_compute_keypair_v2" "test_keypair" {
  name       = "my_pub_key"
  public_key = var.ssh_pub_key
}

# need to add some permissions to the default security group
data "openstack_networking_secgroup_v2" "default_secgroup" {
  name      = "default"
  tenant_id = data.openstack_identity_project_v3.project.id
}

resource "openstack_networking_secgroup_rule_v2" "default_secgroup_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = var.ip_allow_cidr
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = data.openstack_networking_secgroup_v2.default_secgroup.id
}


resource "openstack_networking_secgroup_rule_v2" "default_secgroup_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = var.ip_allow_cidr
  security_group_id = data.openstack_networking_secgroup_v2.default_secgroup.id
}

# Create a test server
resource "openstack_compute_instance_v2" "test_server" {
  count             = "1"
  name              = "test_server"
  image_name        = openstack_images_image_v2.rhel9_2.name
  availability_zone = var.availability_zone
  flavor_name       = "medium"
  key_pair          = openstack_compute_keypair_v2.test_keypair.name
  security_groups   = [data.openstack_networking_secgroup_v2.default_secgroup.name]
  user_data         = file("sample_user-data")

  network {
    port = openstack_networking_port_v2.port_1.id
  }
}
