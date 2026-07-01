#!/bin/bash

# Build the matlab-web-gpu image
docker build -t matlab-web-gpu .

# Run container 1 (Web VNC + GPU)

docker run -d \
    --name matlab_gpu \
    --gpus all \
    --shm-size=2g \
    -p 5901:5901 \
    -p 6080:6080 \
    -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
    matlab-web-gpu
