## Setting up a Statum 1 server inside NREC from scratch
This README explains how to set up a Stratum 1 server on NREC using Terraform, the OpenStack CLI and Ansible.
In addition to the VM running the Stratum 1, we need one more on which Ansible playbooks provided
via EESSI are run. Since the Ansible VM only runs a few scripts to install the Stratum 1 VM, we use the
smallest available flavor (e.g., "m1.small"). For the Stratum 1 VM, we use the "m1.large" flavor and attach
a volume of 200 GB. This disksize should be sufficient to store the software stacks provided by the
EESSI pilot repository. Currently
(2021-04-21) all software stacks (all hardware targets, all versions) consume around 60 GB but this is expected to grow in the coming months.

For full production use we will need to have a volume of at least 1 TB.

To use this guide you need to have installed Terraform and the OpenStack CLI. Check the urls and the
bottom of this document for info on how to do that.

### Some issues with using Terraform for setting up instances in NREC

- difficult syntax, hard to get right
- a lot of destroying and creating to test small changes
- if you put everything into one script (creating zone, volume, security group) then you 
  sometimes have to delete things manually using OpenStack CLI if something goes wrong and you need
  to rerun the script.

I've opted for using Terraform together with OpenStack CLI because some things are easier to just do
outside of a script.

### Procedure

First you need to clone this repo

```console
git clone https://github.com/NorESSI/test-environment-nrec.git
```

Fill in username and password in keystone_rc.sh and then source it

```console
source keystone_rc.sh
```

Put ssh public keys of project members into the file called authorized_keys. One key for each line.

Create a zone (easier to do with openstack command..)

```console
openstack zone create --email parosen@uio.no nessi-prod.uiocloud.no.
```

Create silly keypair (to be used only for adding the authorized_keys in /home/centos/.ssh/authorized_keys on the host)

```console
ssh-keygen -b 2048 -t rsa -f ~/.ssh/terraform-keys -q -N ""
```

Create ansible host in uib-nessi-prod
```console
cd eessi-ansible
terraform 0.13upgrade && terraform init
terraform plan
terraform apply
```

Delete the terraform-key from the project

```console
openstack keypair delete terraform-key
```

Create Stratum 1 host in uib-nessi-prod

```console
cd ../cvmfs-s1-bgo
terraform 0.13upgrade && terraform init
terraform plan
terraform apply
```

Delete terraform-key again

```console
openstack keypair delete terraform-key
```

The VMs eeesi-ansible.nessi-prod.uiocloud.no and cvmfs-s1-bgo-prod.eessi-prod.uiocloud.no are now
created. They can be logged in using the corresponding private ssh keys.

## cvmfs-s1-bgo-prod VM

TODO

## eessi-ansible VM

TODO




Ref.

https://docs.nrec.no/api.html

https://docs.nrec.no/terraform-part1.html

https://docs.nrec.no/terraform-part2.html

https://docs.nrec.no/terraform-part5.html

https://eessi.github.io/docs/filesystem_layer/stratum1/

