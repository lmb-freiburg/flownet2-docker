## Note: Our Caffe version does not work with CuDNN 6
FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04

## Put everything in some subfolder
WORKDIR "/flownet2"

## The build context contains some files which make the raw FlowNet2
## repo fit for Docker
COPY FN2_Makefile.config ./
COPY FN2_run-flownet-docker.py ./

## Switch to non-root user 
ARG uid
ARG gid
ENV uid=${uid}
ENV gid=${gid}
ENV USER=flownet
ENV GROUP=flownet
RUN mkdir -p /home/$USER                                               && \
    echo "${USER}:x:${uid}:${gid}:${USER},,,:/flownet2:/bin/bash"         \
         >> /etc/passwd                                                && \
    echo "${GROUP}:x:${gid}:${uid}"                                       \
         >> /etc/group
RUN apt-get update &&                          \
    apt-get install -y --no-install-recommends \
        module-init-tools                      \
        build-essential                        \
        ca-certificates                        \
        wget                                   \
        git                                    \
        libatlas-base-dev                      \
        libboost-all-dev                       \
        libgflags-dev                          \
        libgoogle-glog-dev                     \
        libhdf5-serial-dev                     \
        libleveldb-dev                         \
        liblmdb-dev                            \
        libopencv-dev                          \
        libprotobuf-dev                        \
        libsnappy-dev                          \
        protobuf-compiler                      \
        python-dev                             \
        python-numpy                           \
        python-scipy                           \
        python-protobuf                        \
        python-pillow                          \
        python-skimage                      && \
    chown ${USER}:${GROUP} /flownet2

USER ${USER}
RUN git clone https://github.com/lmb-freiburg/flownet2                      && \
    cp ./FN2_Makefile.config ./flownet2/Makefile.config                     && \
    cp ./FN2_run-flownet-docker.py ./flownet2/scripts/run-flownet-docker.py && \
    cd flownet2                                                             && \
    rm -rf .git                                                             && \
    cd models                                                               && \
    bash download-models.sh                                                 && \
    rm flownet2-models.tar.gz                                               && \
    cd ..                                                                   && \
    make -j`nproc`                                                          && \
    make -j`nproc` pycaffe

USER root
RUN apt-get remove -y                               \
        module-init-tools                           \
        build-essential                             \
        ca-certificates                             \
        git                                         \
        wget                                     && \
    apt-get install -y --no-install-recommends      \
        sudo                                     && \
    apt-get autoremove -y                        && \
    apt-get autoclean -y                         && \
    rm -rf /var/lib/apt/lists/*

RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL"                                \
         > /etc/sudoers.d/${USER}                                      && \
    chmod 0440 /etc/sudoers.d/${USER} 

USER ${USER}

