ARG TAG=nightly

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    make \
    cmake \
    gcc \
    g++ \
    libtool \
    libtool-bin \
    autoconf \
    automake \
    libncurses5-dev \
    gettext \
    python3-dev \
    python3-pip \
    unzip \
    ninja-build \
    libunibilium-dev \
    libluajit-5.1-dev \
    libutf8proc-dev \
    libmsgpack-dev \
    lua-any \
    libjemalloc-dev 




WORKDIR /usr/src/neovim

# Clone the Neovim repository
RUN git clone https://github.com/neovim/neovim.git .

RUN git checkout ${TAG}

# Build Neovim from source
RUN make CMAKE_BUILD_TYPE=RelWithDebInfo

# Install Neovim system-wide (default is /usr/local)
RUN make install

# My own dependencies
RUN  apt-get install -y \
    jp2a \
    nodejs npm

RUN npm install -g prettier 

ENTRYPOINT ["nvim"]

COPY . /root/.config/nvim

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

