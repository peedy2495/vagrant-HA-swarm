#!/bin/bash

exe=$(realpath $0)
exedir=$(dirname $exe)


if [ ! -d $exedir/gitrepos ]; then
    mkdir $exedir/gitrepos
fi

git clone https://github.com/peedy2495/shell-toolz.git $exedir/gitrepos/shell-toolz 2>/dev/null