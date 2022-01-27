#!/bin/bash

# include toolbox for config manipulations
source $ASSETS/gitrepos/shell-toolz/toolz_configs.sh > >(tee -a /var/log/deployment/toolz.log) 2> >(tee -a /var/log/deployment/toolz.err >&2)

# include toolbox for network procedures
source $ASSETS/gitrepos/shell-toolz/toolz_network.sh > >(tee -a /var/log/deployment/toolz.log) 2> >(tee -a /var/log/deployment/toolz.err >&2)

main() {
    case "${1}" in
        install)
            install;;
        swarm-rollout)
            swarm-rollout;;
    esac
    }

install() {
    echo "Installing Docker..."

    apt install -y gpg software-properties-common

    RELEASE=$(lsb_release -cs)
    NEXUS="$(yq e .services.nexus.ip $ASSETS/environment.yaml):$(yq e .services.nexus.ports.apt $ASSETS/environment.yaml)"

    apt-key add $ASSETS/certs/docker.gpg
    add-apt-repository "deb [arch=$(dpkg --print-architecture)] http://$NEXUS/repository/apt-docker-$RELEASE  $RELEASE  stable"
    apt update

    apt install -y docker-ce

    systemctl enable docker.service --now

    NEXUS_IP=$(yq e .services.nexus.ip $ASSETS/environment.yaml)
    DOCKER_PORT=$(yq e .services.nexus.ports.dockerhub $ASSETS/environment.yaml)

    ReplVar NEXUS_IP $ASSETS/cfg/daemon.json
    ReplVar DOCKER_PORT $ASSETS/cfg/daemon.json

    cp $ASSETS/cfg/daemon.json /etc/docker/daemon.json

    sleep 5
    mkdir /data/docker
    rsync -aP /var/lib/docker/ /data/docker
    mv /var/lib/docker /var/lib/docker.orig
    systemctl restart docker.service
    }

swarm-rollout() {
    echo "Swarm Init..."
    docker swarm init  --advertise-addr eth2 --data-path-addr=eth2

    mtoken=$(docker swarm join-token manager -q)
    wtoken=$(docker swarm join-token worker -q)
    initip=$(ip addr show eth2 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

    # setting up swarm cluster
    sshopts='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

    echo "Monopolize all other nodes ..."
    count=0
    for node in $(yq e .nodes[].name? $ASSETS/environment.yaml); do
        WaitForHost $(yq e .nodes[$count].name $ASSETS/environment.yaml) 22
        if [[ $(yq e .nodes[$count].type $ASSETS/environment.yaml) = "manager" ]]; then
            ssh $sshopts $(yq e .nodes[$count].name $ASSETS/environment.yaml) "docker swarm join --advertise-addr=eth2 --data-path-addr=eth2 --token $mtoken $initip:2377"
        fi
        if [[ $(yq e .nodes[$count].type $ASSETS/environment.yaml) = "worker" ]]; then
            ssh $sshopts $(yq e .nodes[$count].name $ASSETS/environment.yaml) "docker swarm join --advertise-addr=eth2 --data-path-addr=eth2 --token $wtoken $initip:2377"
        fi
        ((count++))
    done
    }

main $@