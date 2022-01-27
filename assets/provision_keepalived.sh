#!/bin/bash

# include toolbox for config manipulations
source $ASSETS/gitrepos/shell-toolz/toolz_configs.sh > >(tee -a /var/log/deployment/toolz.log) 2> >(tee -a /var/log/deployment/toolz.err >&2)

echo Installing keepalived...

# enable ip forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# enable bind of non-local IP addresses
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf

sysctl -p

apt install -y keepalived

#prepare config
install -v -b -m 644 -g root -t /etc/keepalived $ASSETS/cfg/keepalived.conf

VIP=$(yq e .services.keepalived.vip $ASSETS/environment.yaml)
RID=$(yq e .services.keepalived.router-id $ASSETS/environment.yaml)
PWD=$(yq e .keepalived.password $ASSETS/secrets.yaml)

count=0
for node in $(yq e .nodes[].name? $ASSETS/environment.yaml); do
    if [[ $(yq e .nodes[$count].name $ASSETS/environment.yaml) = "$(hostname -s)" ]]; then
        STATE=$(yq e .nodes[$count].keepalived.state $ASSETS/environment.yaml)
        PRIO=$(yq e .nodes[$count].keepalived.prio $ASSETS/environment.yaml)
    fi
    ((count++))
done

for var in VIP RID STATE PRIO PWD; do
  ReplVar $var /etc/keepalived/keepalived.conf
done

# fire it up ... :-)
systemctl enable keepalived.service --now