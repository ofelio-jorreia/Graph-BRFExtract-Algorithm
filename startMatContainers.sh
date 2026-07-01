# container 1
 docker run -d --name matlabContainer1 \
   --gpus all --init -it --rm \
   -p 5901:5901 -p 6080:6080 \
   --shm-size=512M \
   -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
   -w /ofelio \
  mathworks/matlab:r2025a -vnc


# container 2
docker run -d --name matlabContainer2 \
  --gpus all --init -it --rm \
  -p 5902:5901 -p 6081:6080 \
  --shm-size=512M \
  -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
  -w /ofelio \
  mathworks/matlab:r2025a -vnc


# container 3
docker run -d --name matlabContainer3 \
  --gpus all --init -it --rm \
  -p 5903:5901 -p 6082:6080 \
  --shm-size=512M \
  -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
  -w /ofelio \
  mathworks/matlab:r2025a -vnc


# container 4
docker run -d --name matlabContainer4 \
  --gpus all --init -it --rm \
  -p 5904:5901 -p 6083:6080 \
  --shm-size=512M \
  -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
  -w /ofelio \
  mathworks/matlab:r2025a -vnc

# container 5
docker run -d --name matlabContainer5 \
  --gpus all --init -it --rm \
  -p 5905:5901 -p 6084:6080 \
  --shm-size=512M \
  -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
  -w /ofelio \
  mathworks/matlab:r2025a -vnc


# container 6
docker run -d --name matlabContainer6 \
  --gpus all --init -it --rm \
  -p 5906:5901 -p 6085:6080 \
  --shm-size=512M \
  -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
  -w /ofelio \
  mathworks/matlab:r2025a -vnc


# container 7
docker run -d --name matlabContainer7 \
  --gpus all --init -it --rm \
  -p 5907:5901 -p 6086:6080 \
  --shm-size=512M \
  -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
  -w /ofelio \
  mathworks/matlab:r2025a -vnc


# container 8
docker run -d --name matlabContainer8 \
  --gpus all --init -it --rm \
  -p 5908:5901 -p 6087:6080 \
  --shm-size=512M \
  -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
  -w /ofelio \
  mathworks/matlab:r2025a -vnc


# container 9
docker run -d --name matlabContainer9 \
  --gpus all --init -it --rm \
  -p 5909:5901 -p 6088:6080 \
  --shm-size=512M \
  -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
  -w /ofelio \
  mathworks/matlab:r2025a -vnc


# container 10
docker run -d --name matlabContainer10 \
  --gpus all --init -it --rm \
  -p 5910:5901 -p 6089:6080 \
  --shm-size=512M \
  -v /home/ofelio/matlabContainers/myWorkdir:/ofelio \
  -w /ofelio \
  mathworks/matlab:r2025a -vnc


