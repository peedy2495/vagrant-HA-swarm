#!/bin/bash

exe=$(realpath $0)
exedir=$(dirname $exe)

if [ ! -d $exedir/certs ]; then
    mkdir $exedir/certs
fi

# get docker gpg cert
wget -qO $exedir/certs/docker.gpg https://download.docker.com/linux/ubuntu/gpg