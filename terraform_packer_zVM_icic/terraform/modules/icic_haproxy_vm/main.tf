data "openstack_images_image_v2" "img" {
  name_regex   = "^YOUR_BASE_IMAGE_haproxy_.*"
  most_recent = true
}

#
data "openstack_compute_flavor_v2" "size" {
  name = "YOUR_FLAVOUR_NAME"
}

data "openstack_networking_network_v2" "network" {
  name = "YOUR_NETWORK_NAME"
}

data "openstack_compute_keypair_v2" "my_keypair" {
  name       = "YOUR_KEYPAIR_NAME"
}

resource "openstack_compute_instance_v2" "zvm_instance" {
  name      = var.name
  image_id  = data.openstack_images_image_v2.img.id
  flavor_id = data.openstack_compute_flavor_v2.size.id
  network {
    name = "${data.openstack_networking_network_v2.network.name}"
    fixed_ip_v4 = var.ip_address
  }
  availability_zone = var.availability_zone
  key_pair  = data.openstack_compute_keypair_v2.my_keypair.name

  connection {
    type     = "ssh"
    user     = "root"
    private_key = file("~/.ssh/id_ed25519")
    host     = self.access_ip_v4
  }

  provisioner "remote-exec" {
    script = "scripts/wait_for_instance.sh"
  }
}
