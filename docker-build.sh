#!/bin/bash
docker build --rm --build-arg proxy=$http_proxy --rm --tag ros2_nvidia .
