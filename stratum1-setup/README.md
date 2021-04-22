## Setting up a Statum 1 server inside NREC from scratch
This README explains how to set up a Stratum 1 server on NREC using Terraform, the OpenStack CLI and Ansible.
In addition to the VM running the Stratum 1, we need one more on which Ansible playbooks provided
via EESSI are run. Since the Ansible VM only runs a few scripts to install the Stratum 1 VM, we use the
smallest available flavor (e.g., "m1.small"). For the Stratum 1 VM, we use the "m1.large" flavor and attach
a volume of 200 GB. This disksize should be sufficient to store the software stacks provided by the
EESSI pilot repository. Currently (2021-04-21) all software stacks (all hardware targets, all
versions) consume around 60 GB but this is expected to grow in the coming months.

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

When following this procedure, these two instances will be reachable by ping and ssh from all UiO
and UiB machines. Getting access is done by adding ssh public keys inside
/home/centos/.ssh/authorized_keys on both VMs. A records (ipv4) and AAAA records (ipv6) are created
so that the VMs are easily identified by their hostname under the subzone nessi-prod.uiocloud.no

First you need to clone this repo:

```console
git clone https://github.com/NorESSI/test-environment-nrec.git
```

Fill in username and password in keystone_rc.sh and then source it:

```console
source keystone_rc.sh
```

Put ssh public keys of project members into the file called authorized_keys. One key for each line.

Create a zone (easier to do with openstack command..):

```console
openstack zone create --email parosen@uio.no nessi-prod.uiocloud.no.
```

Create silly keypair (to be used only for adding the authorized_keys in /home/centos/.ssh/authorized_keys on the host):

```console
ssh-keygen -b 2048 -t rsa -f ~/.ssh/terraform-keys -q -N ""
```

Create ansible host in uib-nessi-prod:

```console
cd eessi-ansible
terraform 0.13upgrade && terraform init
terraform plan
terraform apply
```

Delete the terraform-key from the project:

```console
openstack keypair delete terraform-key
```

Create Stratum 1 host in uib-nessi-prod:

```console
cd ../cvmfs-s1-bgo
terraform 0.13upgrade && terraform init
terraform plan
terraform apply
```

Delete terraform-key again:

```console
openstack keypair delete terraform-key
```

The VMs eeesi-ansible.nessi-prod.uiocloud.no and cvmfs-s1-bgo-prod.eessi-prod.uiocloud.no are now
created. They can be logged in using the corresponding private ssh keys.

## cvmfs-s1-bgo-prod VM

Mount volume:

```console
sudo mkfs.ext4 /dev/sdb
sudo mount /dev/sdb /srv
```

## eessi-ansible VM

Clone filesystem-layer repo from the EESSI github page:

```console
git clone https://github.com/EESSI/filesystem-layer.git && cd filesystem-layer
```

Change name of example files:

```console
mv inventory/local_site_specific_vars.yml.example inventory/local_site_specific_vars.yml
mv inventory/hosts.example inventory/hosts
```

Add this line with the correct key to inventory/local_site_specific_vars.yml: (key was created by Thomas Röblitz)

```
cvmfs_geo_license_key: "put your key here"
```

Add IP address of the Stratum 1 VM (cvmfs-s1-bgo-prod in this case) in the inventory/hosts file:

```
[cvmfsstratum1servers]
"158.39.77.xx"
```

Install Ansible
```console
sudo yum install -y ansible
```

Then install Ansible roles for EESSI:

```console
ansible-galaxy role install -r requirements.yml -p ./roles --force
```

Create ssh keys for accessing the Stratum 1 server:

```console
ssh-keygen -b 2048 -t rsa -f ~/.ssh/ansible-host-keys -q -N ""
```

Make sure the ansible-host-keys.pub is in the $HOME/.ssh/authorized_keys file on your Stratum 1 server.

```console
ansible-playbook -b --private-key ~/.ssh/ansible-host-keys -e @inventory/local_site_specific_vars.yml stratum1.yml
```

About 70 min later you will have you Stratum 1 server up and running. 

## Test locally on other VM

Download and install the CVMFS client rpm:

```console
yum install https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
yum install -y cvmfs
```

Download and install the EESSI-specific configuration package: 

```console
wget https://github.com/EESSI/filesystem-layer/releases/download/v0.3.1/cvmfs-config-eessi-0.3.1-1.noarch.rpm
sudo rpm -ivh cvmfs-config-eessi-0.3.1-1.noarch.rpm
```

Add these two lines to /etc/cvmfs/default.local

```
CVMFS_CLIENT_PROFILE=single
CVMFS_QUOTA_LIMIT=40000
```

Add the url to our new Stratum 1 to the CMVFS_SERVER_URL variable in /etc/cvmfs/config.d/pilot.eessi-hpc.org.local:

```
CVMFS_SERVER_URL="http://cvmfs-s1-rug.eessi-hpc.org/cvmfs/@fqrn@;http://cvmfs-s1-bgo.nessi-prod.uiocloud.no/cvmfs/@fqrn@"
```

Reload the config and run the cvmfs_talk command:

```console
sudo cvmfs_config reload pilot.eessi-hpc.org
sudo cvmfs_talk -i pilot.eessi-hpc.org host info
```

It should show something like this with your new server at the top:

```bash
[0] http://cvmfs-s1-bgo.nessi-prod.uiocloud.no/cvmfs/pilot.eessi-hpc.org (geographically ordered)
[1] http://cvmfs-s1-rug.eessi-hpc.org/cvmfs/pilot.eessi-hpc.org (geographically ordered)
Active host 0: http://cvmfs-s1-bgo.eessi-hpc.org/cvmfs/pilot.eessi-hpc.org
```

Since our new Stratum 1 server is closest to us (hopefully!) we can now test it by sourcing the init
file and loading a module:

```console
source /cvmfs/pilot.eessi-hpc.org/latest/init/bash
[EESSI pilot 2021.03] $ module avail
[EESSI pilot 2021.03] $ module load Python/3.8.2-GCCcore-9.3.0
[EESSI pilot 2021.03] $ python
Python 3.8.2 (default, Apr  9 2021, 18:30:18)
[GCC 9.3.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>

When testing is done you can ask Jaco can Dijk on the EESSI Slack to add a new DNS forwarding of
cvmfs-s1-bgo.eessi-hpc.org to cvmfs-s1-bgo.nessi-prod.uiocloud.no

```

Ref.

https://docs.nrec.no/api.html

https://docs.nrec.no/terraform-part1.html

https://docs.nrec.no/terraform-part2.html

https://docs.nrec.no/terraform-part5.html

https://eessi.github.io/docs/filesystem_layer/stratum1/

