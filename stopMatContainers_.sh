#!/bin/bash

NUM_CONTAINERS=10

for ((i=1; i<=NUM_CONTAINERS; i++)); do
    docker stop matlabContainer${i}
done
