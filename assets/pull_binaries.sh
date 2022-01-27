#!/bin/bash

exe=$(realpath $0)
exedir=$(dirname $exe)


if [ ! -d $exedir/bin ]; then
    mkdir $exedir/bin
fi

# get yq yaml-parser
wget -qO $exedir/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64