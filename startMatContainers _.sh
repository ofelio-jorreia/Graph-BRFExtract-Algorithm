#!/bin/bash

NUM_CONTAINERS=10
HOST_VNC_PORT=5901
HOST_WEB_PORT=6080

for ((i=1; i<=NUM_CONTAINERS; i++)); do
    docker run -d \
        --name matlabContainer${i} \
        --gpus all \
        --init \
        -it \
        --rm \
        -p $((HOST_VNC_PORT+i-1)):5901 \
        -p $((HOST_WEB_PORT+i-1)):6080 \
        --shm-size=512M \
        -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
        -w /ofelio \
        mathworks/matlab:r2025a \
        -vnc

    echo "Started matlabContainer${i} (VNC: $((HOST_VNC_PORT+i-1)), Web: $((HOST_WEB_PORT+i-1)))"
done
