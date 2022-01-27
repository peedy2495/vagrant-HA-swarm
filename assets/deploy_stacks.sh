#!/bin/bash

# include toolbox for config manipulations
source $ASSETS/gitrepos/shell-toolz/toolz_configs.sh > >(tee -a /var/log/deployment/toolz.log) 2> >(tee -a /var/log/deployment/toolz.err >&2)

for stack in $ASSETS/stacks/*.yaml; do
    stackname="$stack"
    stackname="${stackname##*_}"
    stackname="${stackname%.*}"
    SRC="$(yq e .services.glusterfs.mntpath $ASSETS/environment.yaml)/$stackname"
    echo "---$SRC---"
    echo "---$stack---"
    mkdir $SRC
    #ReplVar SRC $stack  doesn't work with paths, yet ... now hardcoded in stackconfig
    docker stack deploy --compose-file $stack $stackname
done
