# Security group
resource "openstack_networking_secgroup_v2" "instance_access" {
    name = "ssh-icmp-uio-uib"
    description = "Allows SSH and ICMP access from UiO and UiB"
}

# Allow ssh from IPv4 net UiO
resource "openstack_networking_secgroup_rule_v2" "rule_ssh_access_ipv4_uio" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol  = "tcp"
    port_range_min = 22
    port_range_max = 22
    remote_ip_prefix = "129.240.0.0/16"
    security_group_id = openstack_networking_secgroup_v2.instance_access.id
}

# Allow ssh from IPv4 net UiB
resource "openstack_networking_secgroup_rule_v2" "rule_ssh_access_ipv4_uib" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol  = "tcp"
    port_range_min = 22
    port_range_max = 22
    remote_ip_prefix = "129.177.0.0/16"
    #remote_ip_prefix = "158.39.0.0/16"
    security_group_id = openstack_networking_secgroup_v2.instance_access.id
}

# Allow ssh from IPv6 net UiO
resource "openstack_networking_secgroup_rule_v2" "rule_ssh_access_ipv6_uio" {
    direction = "ingress"
    ethertype = "IPv6"
    protocol  = "tcp"
    port_range_min = 22
    port_range_max = 22
    remote_ip_prefix = "2001:700:100::/40"
    security_group_id = openstack_networking_secgroup_v2.instance_access.id
}

# Allow ssh from IPv6 net UiB
resource "openstack_networking_secgroup_rule_v2" "rule_ssh_access_ipv6_uib" {
    direction = "ingress"
    ethertype = "IPv6"
    protocol  = "tcp"
    port_range_min = 22
    port_range_max = 22
    remote_ip_prefix = "2001:700:200::/48"
    security_group_id = openstack_networking_secgroup_v2.instance_access.id
}

# Allow icmp from IPv4 net UiO
resource "openstack_networking_secgroup_rule_v2" "rule_icmp_access_ipv4_uio" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol  = "icmp"
    remote_ip_prefix = "129.240.0.0/16"
    security_group_id = openstack_networking_secgroup_v2.instance_access.id
}

# Allow icmp from IPv4 net UiB
resource "openstack_networking_secgroup_rule_v2" "rule_icmp_access_ipv4_uib" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol  = "icmp"
    remote_ip_prefix = "129.177.0.0/16"
    #remote_ip_prefix = "158.39.0.0/16"
    security_group_id = openstack_networking_secgroup_v2.instance_access.id
}

# Allow icmp from IPv6 net UiO
resource "openstack_networking_secgroup_rule_v2" "rule_icmp_access_ipv6_uio" {
    direction = "ingress"
    ethertype = "IPv6"
    protocol = "icmp"
    remote_ip_prefix = "2001:700:100::/40"
    security_group_id = openstack_networking_secgroup_v2.instance_access.id
}

# Allow icmp from IPv6 net UiB
resource "openstack_networking_secgroup_rule_v2" "rule_icmp_access_ipv6_uib" {
    direction = "ingress"
    ethertype = "IPv6"
    protocol = "icmp"
    remote_ip_prefix = "2001:700:200::/48"
    security_group_id = openstack_networking_secgroup_v2.instance_access.id
}

resource "openstack_compute_keypair_v2" "tf-keypair" {
  name       = "terraform-key"
  public_key = file("~/.ssh/terraform-keys.pub")
}

resource "openstack_compute_instance_v2" "testnode" {
    name = "eessi-ansible"
    image_name = "GOLD CentOS 7"
    flavor_name = "m1.small"
    key_pair = openstack_compute_keypair_v2.tf-keypair.name
    security_groups = ["default","ssh-icmp-uio-uib" ]

    network {
        name = "dualStack"
    }

    lifecycle {
        ignore_changes = [image_name]
    }
}

resource "null_resource" "authkeys" {
  depends_on = [openstack_compute_instance_v2.testnode]
  provisioner "file" {
    source      = "../authorized_keys"
    destination = "/home/centos/.ssh/authorized_keys"
    }
  connection {
    host        = openstack_compute_instance_v2.testnode.network.0.fixed_ip_v4
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
  name        = "${openstack_compute_instance_v2.testnode.name}.${var.nessi_zone_name}."
  type        = "A"
  records     = [openstack_compute_instance_v2.testnode.access_ip_v4]
}

# Create records for AAAA (IPv6)
resource "openstack_dns_recordset_v2" "aaaa_records" {
  zone_id     = data.openstack_dns_zone_v2.nessi_zone.id
  name        = "${openstack_compute_instance_v2.testnode.name}.${var.nessi_zone_name}."
  type        = "AAAA"
  records     = [openstack_compute_instance_v2.testnode.access_ip_v6]
}
