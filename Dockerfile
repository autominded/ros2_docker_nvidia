FROM nvidia/cudagl:10.0-devel-ubuntu16.04
# COPY ZscalerRootCA.crt /usr/local/share/ca-certificates/ZscalerRootCA.crt
# RUN update-ca-certificates

ARG proxy

ENV http_proxy $proxy
ENV https_proxy $proxy

RUN echo "check_certificate = off" >> ~/.wgetrc
RUN echo "[global] \n\
trusted-host = pypi.python.org \n \
\t               pypi.org \n \
\t              files.pythonhosted.org" >> /etc/pip.conf

# >> START Install base software
# Basic update and Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales ca-certificates &&  rm -rf /var/lib/apt/lists/*

# Locale set to something minimal like POSIX
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Exit when RUN get non-zero value
RUN set -e 

# Get basic packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        wget \
        git \
        python \
        python-dev \
        python-pip \
        python-wheel \
        python-numpy \
        python3 \
        python3-dev \
        python3-pip \
        python3-wheel \
        python3-numpy \
        python3-setuptools \
        libcurl3-dev  \
        gcc \
        sox \
        libsox-fmt-mp3 \
        htop \
        nano \
        swig \
        cmake \
        libboost-all-dev \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        pkg-config \
        libsox-dev 

# Install pip
RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

# Remove default opencv from system and install opencv3.3.0 - 
RUN apt-get purge libopencv* 
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev \
    libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev \
    libgtk-3-dev \
    libatlas-base-dev gfortran \
    unzip \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev 

RUN ln -s /usr/include/libv4l1-videodev.h  /usr/include/linux/videodev.h

# Fetch OpenCV
RUN cd /opt && git clone --verbose https://github.com/opencv/opencv.git -b 3.3.0 &&\
    cd /opt && wget https://github.com/opencv/opencv_contrib/archive/3.3.0.tar.gz &&\
    mkdir opencv_contrib && tar -xf 3.3.0.tar.gz -C opencv_contrib --strip-components 1

RUN cd /opt/opencv && mkdir release && cd release && \
    cmake -G "Unix Makefiles" -DENABLE_PRECOMPILED_HEADERS=OFF -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
    CMAKE_C_COMPILER=/usr/bin/gcc -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DWITH_TBB=ON -DBUILD_NEW_PYTHON_SUPPORT=ON -DWITH_V4L=ON -DINSTALL_C_EXAMPLES=ON \
    -DINSTALL_PYTHON_EXAMPLES=ON -DBUILD_EXAMPLES=OFF  -DWITH_OPENGL=ON \
    -DWITH_CUDA=OFF -DCUDA_GENERATION=Auto -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
    .. &&\
    make -j"$(nproc)"  && \
    make install && \
    ldconfig &&\
    cd /opt/opencv/release && make clean

# Install protobuf 3.4.0 -- >> 
RUN apt-get update && apt-get -y --no-install-recommends install autoconf automake libtool make g++ unzip

RUN mkdir -p /home/root/protobuf_c/ && cd /home/root/protobuf_c/ && \
    git clone https://github.com/protocolbuffers/protobuf.git && \
    cd protobuf && git checkout v3.4.0 && \ 
    git submodule update --init --recursive && \
    ./autogen.sh && \
    ./configure && \
    make -j$(nproc) && \
    make install

# Install orocos_kinematics -- >> 
RUN apt-get  -y --no-install-recommends install libeigen3-dev
RUN mkdir /home/root/orocos_c/ && cd /home/root/orocos_c/ && \
    git clone https://github.com/orocos/orocos_kinematics_dynamics.git && \
    cd orocos_kinematics_dynamics/orocos_kdl && \
    mkdir build &&  cd build && \
    cmake .. &&  make -j$(nproc) && make install 

# ROS2 Dep
RUN apt-get update && apt-get install -y --no-install-recommends curl gnupg2 lsb-release
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN sh -c 'echo "deb [arch=amd64,arm64] http://packages.ros.org/ros2/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list'

RUN apt-get update && apt-get install -y \
    python3-colcon-common-extensions \
    python3-lark-parser \
    python3-pip \
    python-rosdep \
    python3-vcstool

# Install some pip packages needed for ROS2 testing 
RUN python3 -m pip install -U \
    argcomplete \
    flake8 \
    flake8-blind-except \
    flake8-builtins \
    flake8-class-newline \
    flake8-comprehensions \
    flake8-deprecated \
    flake8-docstrings \
    flake8-import-order \
    flake8-quotes \
    pytest-repeat \
    pytest-rerunfailures \
    pytest \
    pytest-cov \
    pytest-runner \
    setuptools

# Install Fast-RTPS dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libasio-dev \
    libtinyxml2-dev

# Install pcl, gsl, glog, LevelDB, libusb header and urdfdom -- >>
RUN apt-get update && apt-get install  -y --no-install-recommends libpcl-dev \
    libgsl-dev \
    liburdfdom-dev \
    libgflags-dev libgoogle-glog-dev liblmdb-dev \
    libleveldb-dev 

# Install Libusb header and update database -- >> 
RUN apt-get update && apt-get install  -y --no-install-recommends libusb-1.0-0-dev mlocate && \
    updatedb && locate libusb.h libopenblas-dev

# Weird OpenCV softlink errors during ament build -- >> 
RUN cd /usr/local/lib/ && \
    ln -s libopencv_highgui.so.3.3 libopencv_highgui3.so.3.3 && \
    ln -s libopencv_videoio.so.3.3 libopencv_videoio3.so.3.3 && \
    ln -s libopencv_imgcodecs.so.3.3 libopencv_imgcodecs3.so.3.3 && \
    ln -s libopencv_imgproc.so.3.3 libopencv_imgproc3.so.3.3 && \
    ln -s libopencv_core.so.3.3 libopencv_core3.so.3.3
    
# Done
# RUN useradd -u 8877 admin1

# USER admin1
RUN apt install -y libopenblas-dev libxaw7-dev liborocos-kdl1.3 libpoco-dev libpocofoundation9v5  libpocofoundation9v5-dbg python-empy python3-dev python3-empy  python3-nose python3-pip python3-setuptools python3-vcstool python3-yaml libtinyxml-dev libeigen3-dev  clang-format pydocstyle pyflakes  python3-coverage python3-mock python3-pep8 uncrustify libasio-dev libtinyxml2-dev build-essential cppcheck cmake  
 ## ROS2 Setup
RUN locale-gen en_US en_US.UTF-8
RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RUN export LANG=en_US.UTF-8
RUN apt update &&  apt install curl gnupg2 lsb-release
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN sh -c 'echo "deb [arch=amd64,arm64] http://packages.ros.org/ros2/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list'
RUN apt update && apt install -y \
  build-essential \
  cmake \
  git \
  python3-colcon-common-extensions \
  python3-pip \
  python-rosdep \
  python3-vcstool \
  wget
# install some pip packages needed for testing
RUN python3 -m pip install -U \
  argcomplete \
  flake8 \
  flake8-blind-except \
  flake8-builtins \
  flake8-class-newline \
  flake8-comprehensions \
  flake8-deprecated \
  flake8-docstrings \
  flake8-import-order \
  flake8-quotes \
  pytest-repeat \
  pytest-rerunfailures \
  pytest \
  pytest-cov \
  pytest-runner \
  setuptools
# install Fast-RTPS dependencies
RUN apt install --no-install-recommends -y \
  libasio-dev \
  libtinyxml2-dev
# install CycloneDDS dependencies
RUN apt install --no-install-recommends -y \
  libcunit1-dev
RUN mkdir -p ~/ros2_dashing/src
#RUN cd ~/ros2_dashing && wget https://raw.githubusercontent.com/ros2/ros2/dashing/ros2.repos && vcs import src < ros2.repos
#RUN rosdep init && rosdep install --from-paths src --ignore-src --rosdistro dashing -y --skip-keys "console_bridge fastcdr fastrtps libopensplice67 libopensplice69 rti-connext-dds-5.3.1 urdfdom_headers"
#RUN cd ~/ros2_dashing/ &&  apt-get -y install software-properties-common && apt update && apt install -y  clang && export CC=clang && export CXX=clang++ && colcon build --cmake-force-configure && colcon build --symlink-install
