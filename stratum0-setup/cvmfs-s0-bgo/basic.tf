
resource "openstack_compute_keypair_v2" "tf-keypair" {
  name       = "terraform-keys-s0"
  public_key = file("~/.ssh/terraform-keys.pub")
}

resource "openstack_compute_instance_v2" "instance" {
    name = "cvmfs-local-s0-bgo"
    image_name = "GOLD Rocky Linux 8"
    flavor_name = "m1.large"
    key_pair = openstack_compute_keypair_v2.tf-keypair.name
    security_groups = ["default","ssh-icmp-uio-uib", "s1-http" ]

    network {
        name = "dualStack"
    }

    lifecycle {
        ignore_changes = [image_name]
    }
}

resource "null_resource" "authkeys" {
  depends_on = [openstack_compute_instance_v2.instance]
  provisioner "file" {
    source      = "../authorized_keys.ori"
    destination = "/home/centos/.ssh/authorized_keys"
    }
  connection {
    host        = openstack_compute_instance_v2.instance.network.0.fixed_ip_v4
    type        = "ssh"
    user        = "centos"
    private_key = file("~/.ssh/terraform-keys")
    timeout     = "45s"
    }
}

# existing DNS zone
variable "nessi_zone_name" {
  default = "nessi-prod.uiocloud.no"
}

# Find zone info
data "openstack_dns_zone_v2" "nessi_zone" {
  name = "${var.nessi_zone_name}."
}


# Create records for A (IPv4)
resource "openstack_dns_recordset_v2" "a_records" {
  zone_id     = data.openstack_dns_zone_v2.nessi_zone.id
  name        = "${openstack_compute_instance_v2.instance.name}.${var.nessi_zone_name}."
  type        = "A"
  records     = [openstack_compute_instance_v2.instance.access_ip_v4]
}

# Create records for AAAA (IPv6)
resource "openstack_dns_recordset_v2" "aaaa_records" {
  zone_id     = data.openstack_dns_zone_v2.nessi_zone.id
  name        = "${openstack_compute_instance_v2.instance.name}.${var.nessi_zone_name}."
  type        = "AAAA"
  records     = [openstack_compute_instance_v2.instance.access_ip_v6]
}

# Create volume
resource "openstack_blockstorage_volume_v2" "volume" {
    name = "s0-local-software-stack"
    size = "100"
}

# Attach volume
resource "openstack_compute_volume_attach_v2" "volumes" {
    instance_id = openstack_compute_instance_v2.instance.id
    volume_id = openstack_blockstorage_volume_v2.volume.id
}
