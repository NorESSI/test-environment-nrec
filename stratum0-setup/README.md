## Setting up a local Stratum 0 server in NREC

The Stratum0 server 'cvmfs-local-s0-bgo.nessi-prod.uiocloud.no' was set up in NREC using
`Terraform`. The `basic.tf` file is a modified version of the file I used for the Stratum1
setup. The image used is `GOLD Rocky Linux 8` and the flavor is `m1.large`. A 100G drive
is attached.

The installation of `CVMFS` on this VM was done using this
[guide](https://cvmfs-contrib.github.io/cvmfs-tutorial-2021/02_stratum0_client/).

#### Setting up the Stratum 0
Install the cvmfs client and server:

```bash
sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
sudo yum install -y cvmfs cvmfs-server
```

Enable httpd:

```bash
sudo systemctl enable httpd
sudo systemctl start httpd
sudo systemctl status httpd
```

Cvmfs config:

```bash
MY_REPO_NAME=repo.nessi.uiocloud.no
sudo cvmfs_server mkfs -o $USER ${MY_REPO_NAME}
cvmfs_server transaction ${MY_REPO_NAME}
```

Create a test script and publish it:

```bash
echo '#!/bin/bash' > /cvmfs/${MY_REPO_NAME}/hello.sh
echo 'echo hello' >> /cvmfs/${MY_REPO_NAME}/hello.sh
chmod a+x /cvmfs/${MY_REPO_NAME}/hello.sh
cvmfs_server publish ${MY_REPO_NAME}
```

Create cronjob for resigning the whitelist (otherwise it will expire within 30 days if not
resigned):

```bash
echo '0 11 * * 1 root /usr/bin/cvmfs_server resign repo.nessi.uiocloud.no' | sudo tee -a /etc/cron.d/cvmfs_resign
```


#### Test direct access to the Stratum0 from a client

Install the client:

```bash
sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
sudo yum install -y cvmfs
```


Add the public key `/etc/cvmfs/keys/repo.nessi.uiocloud.no.pub` from the Stratum 0 server to
`/etc/cvmfs/keys/uiocloud.no` on the client:

```bash
sudo mkdir /etc/cvmfs/keys/uiocloud.no
sudo vim repo.nessi.uiocloud.no.pub
sudo chmod 444 repo.nessi.uiocloud.no.pub
```

Configure cvmfs to talk to our new Stratum 0. 

```bash
echo 'CVMFS_SERVER_URL="http://158.39.77.6/cvmfs/@fqrn@"' | sudo tee -a /etc/cvmfs/config.d/repo.nessi.uiocloud.no.conf
echo 'CVMFS_KEYS_DIR="/etc/cvmfs/keys/uiocloud.no"' | sudo tee -a /etc/cvmfs/config.d/repo.nessi.uiocloud.no.conf
echo 'CVMFS_HTTP_PROXY=DIRECT' | sudo tee -a /etc/cvmfs/default.local
echo 'CVMFS_QUOTA_LIMIT=5000' | sudo tee -a /etc/cvmfs/default.local
sudo cvmfs_config setup
sudo cvmfs_config chksetup
```

You can check that the config is correct with:

```bash
cvmfs_config showconfig repo.nessi.uiocloud.no |grep -Ei 'CVMFS_HTTP_PROXY|CVMFS_KEYS_DIR'
```

Now access files form the repo:

```bash
ls /cvmfs/repo.nessi.uiocloud.no
```


NB! If something goes wrong, you can try killing any cvmfs process and rerun the setup:

```bash
sudo cvmfs_config killall && sudo cvmfs_config setup
```

