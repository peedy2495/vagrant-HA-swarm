#!/bin/bash

# get initial asset-path fom hypervisor
ASSETS=$1

# make asset-root persistent for future provisions
echo "export ASSETS=$ASSETS" >/etc/profile.d/assets.sh

mkdir /var/log/deployment

# install yq command
cp $ASSETS/bin/yq /usr/local/sbin
chmod 755 /usr/local/sbin/yq

REPO_IP=$(yq e .services.nexus.ip $ASSETS/environment.yaml)
REPO_PORT=$(yq e .services.nexus.ports.apt $ASSETS/environment.yaml)

# include toolbox for config manipulations
source $ASSETS/gitrepos/shell-toolz/toolz_configs.sh > >(tee -a /var/log/deployment/toolz.log) 2> >(tee -a /var/log/deployment/toolz.err >&2)

# Use local Nexus apt-proxy
ReplVar REPO_IP $ASSETS/cfg/sources.list
ReplVar REPO_PORT $ASSETS/cfg/sources.list
cp $ASSETS/cfg/sources.list /etc/apt/sources.list

# Push system into latest
apt update  > >(tee -a /var/log/deployment/os-basic.log) 2> >(tee -a /var/log/deployment/os-basic.err >&2)
apt install -y avahi-daemon libnss-mdns   > >(tee -a /var/log/deployment/os-basic.log) 2> >(tee -a /var/log/deployment/os-basic.err >&2)
apt -y upgrade  > >(tee -a /var/log/deployment/os-basic.log) 2> >(tee -a /var/log/deployment/os-basic.err >&2)
apt -y dist-upgrade  > >(tee -a /var/log/deployment/os-basic.log) 2> >(tee -a /var/log/deployment/os-basic.err >&2)

# passwordless root access for guests vice versa
mkdir /root/.ssh
cp $ASSETS/certs/id_rsa* /root/.ssh/
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
KeyEnable PubkeyAuthentication /etc/ssh/sshd_config
systemctl restart sshd

# setup fqdn hostname
echo "$HOSTNAME$(yq e .env_common.domain $ASSETS/environment.yaml)" >/etc/hostname

# setting up local name resolution for the whole environment
domain=$(yq e .env_common.domain $ASSETS/environment.yaml)
#sed -i "/$(hostname -s)/d" /etc/hosts
count=0
for node in $(yq e .nodes[].name? $ASSETS/environment.yaml); do
    echo -e "$(yq e .nodes[$count].interfaces[1].ip $ASSETS/environment.yaml)\t\t $node" >>/etc/hosts
    echo -e "$(yq e .nodes[$count].interfaces[1].ip $ASSETS/environment.yaml)\t\t $node$domain" >>/etc/hosts
    ((count++))
done

# prepare separate data volume
datadisk=$(yq e .env_common.datadisk $ASSETS/environment.yaml)
mkdir /data
chmod go+rw /data
mkfs.ext4 $datadisk
echo "$datadisk        /data   ext4    defaults        0 1" >> /etc/fstab
mount -a