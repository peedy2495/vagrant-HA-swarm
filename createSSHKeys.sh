#!/bin/bash

exe=$(realpath $0)
exedir=$(dirname $exe)

if [ ! -f assets/certs/id_rsa ]; then
    ssh-keygen -t rsa -P "" -f $exedir/certs/id_rsa
fi