## Setting up a Statum 1 server inside NREC from scratch
This quide shows how I set up a Stratum 1 server in NREC using Terraform and the OpenStack CLI. For
this two VMs are needed, one for setting up ansible with EESSI settings, and one for the actual
Stratum 1 server. Since the ansible VM is just needed to install the Stratum 1 VM, we can use the
"m1.small" flavor. For the Stratum 1 VM we use the "m1.large" flavor together with an additional
volume of 200GB. This disksize should be sufficient for a while during the pilot phase. Currently
(2021-04-21) the whole software stack takes up around 60GB but this is expected to grow quite fast.
For production use we will need to have a volume of at least 1TB.

To use this guide you need to have installed Terraform and the OpenStack CLI. Check the urls and the
bottom of this document for info on how to do that.

### Problems using Terraform

- difficult syntax, hard to get right
- a lot of destroying and creating to test small changes
- if you put everything into one script (creating zone, volume, security group) then you have to delete manually if something goes wrong and you need
  to rerun the script.

I've opted for using Terraform together with OpenStack CLI because some things are easier to just do
outside of a script.

First you need to clone this repo

```console
git clone https://github.com/NorESSI/test-environment-nrec.git
```

Fill in username and password in keystone_rc.sh

```console
source keystone_rc.sh
```

Put ssh public keys of project members into the file called authorized_keys. One key for each line.

Create zone (easier to do with openstack command..)

```console
openstack zone create --email parosen@uio.no nessi-prod.uiocloud.no.
```

Create silly keypair (to be used only for adding the authorized_keys in /home/centos/.ssh/authorized_keys on the host

```console
ssh-keygen -b 2048 -t rsa -f ~/.ssh/terraform-keys -q -N ""
```

Create ansible host in uib-nessi-prod
```console
cd eessi-ansible
```
```console
terraform 0.13upgrade && terraform init
terraform plan
terraform apply
```

Delete the terraform-key from the project

```console
openstack keypair delete terraform-key
```

Created stratum 1 host in uib-nessi-prod

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

