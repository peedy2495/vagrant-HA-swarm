#!/bin/bash

# include toolbox for network procedures
source $ASSETS/gitrepos/shell-toolz/toolz_network.sh > >(tee -a /var/log/deployment/toolz.log) 2> >(tee -a /var/log/deployment/toolz.err >&2)

domain=$(yq e .env_common.domain $ASSETS/environment.yaml)
volname=$(yq e .services.glusterfs.volname $ASSETS/environment.yaml)
volpath=$(yq e .services.glusterfs.volpath $ASSETS/environment.yaml)
mntpath=$(yq e .services.glusterfs.mntpath $ASSETS/environment.yaml)

main() {
    case "${1}" in
        install)
            install;;
        peer)
            peer;;
        mkvol)
            make-volume;;
        mntvol)
            mount-volume;;
    esac
    }

install() {
    apt install -y glusterfs-server
    systemctl enable glusterd --now
    mkdir -p $volpath
    }

peer() {
    # peering all gluster servers
    for node in $(yq e .nodes[].name? $ASSETS/environment.yaml); do
        WaitForHost $node 24007
        gluster peer probe $node$domain
        sleep 3
    done
    }

make-volume() {
    # create volume gfs-docker for HA swarm environment
    count=0
    for node in $(yq e .nodes[].name? $ASSETS/environment.yaml); do
        ((count++))
        nodevols="$nodevols $node:$volpath"
    done
    gluster volume create gfs-docker replica $count $nodevols force
    gluster volume start gfs-docker
    }

mount-volume() {
    while [[ $(gluster volume list) != $volname ]]; do
        echo "Waiting for Volume $volname" 
        sleep 5
    done
    echo "Volume $volname is now available"
    mkdir $mntpath
    chmod go+r $mntpath 
    echo "$HOSTNAME:/$volname $mntpath glusterfs defaults,_netdev,fetch-attempts=10,backupvolfile-server=localhost 0 0" >> /etc/fstab
    sleep 10 #availability != usability :-( ;necessary to prevent hickups
    mount -a
    }

main $@