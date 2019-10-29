#!/bin/bash

docker run -it \
    -e uid=$UID \
    -e LOCAL_USER_ID=`id -u` \
    -v ~/.Xauthority:~/.Xauthority \
    -v /tmp/.X11-unix:/tmp/.X11-unix -e XAUTHORITY= ~/.Xauthority -e DISPLAY=unix$DISPLAY \
    --privileged \
    --net="host" -p 8050:8050 -p 5023:5023 --device /dev/dri \
    -e LOCAL_USER_ID=`id -u` \
    --rm -v `pwd`:/dockruntime -e http_proxy -e https_proxy \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    --gpus all \
    --runtime=nvidia \
    --workdir /ros2_nvidia ros2_nvidia:latest
