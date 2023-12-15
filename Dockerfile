#based on /tg/station byond image

FROM ubuntu:jammy AS base
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates

FROM base AS byond
WORKDIR /byond

RUN apt-get install -y --no-install-recommends \
        curl \
        unzip \
        make \
        libstdc++6:i386

# byond version
ENV  BYOND_MAJOR=514
ENV  BYOND_MINOR=1588

#rust_g git tag
ENV  RUST_G_VERSION=3.0.0

#node version
ENV  NODE_VERSION=14
ENV  NODE_VERSION_PRECISE=14.16.1

# SpacemanDMM git tag
ENV  SPACEMAN_DMM_VERSION=suite-1.7.3

# Python version for mapmerge and other tools
ENV  PYTHON_VERSION=3.9.0

#auxlua repo
ENV  AUXLUA_REPO=tgstation/auxlua

#auxlua git tag
ENV  AUXLUA_VERSION=1.4.1





ENV  BYOND_MAJOR=515
ENV  BYOND_MINOR=1620

#rust_g git tag
ENV  RUST_G_VERSION=3.0.0

#node version
ENV  NODE_VERSION=14
ENV  NODE_VERSION_PRECISE=14.16.1

# SpacemanDMM git tag
ENV  SPACEMAN_DMM_VERSION=suite-1.8

# Python version for mapmerge and other tools
ENV  PYTHON_VERSION=3.9.0

#auxlua repo
ENV  AUXLUA_REPO=tgstation/auxlua

#auxlua git tag
ENV  AUXLUA_VERSION=1.4.1

#hypnagogic repo
ENV  CUTTER_REPO=actioninja/hypnagogic

#hypnagogic git tag
ENV  CUTTER_VERSION=v3.0.1
    
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y \
    nano \
    curl \
    unzip \
    zip \
    make \
    libstdc++6 \
    tzdata \
    ca-certificates \
    openjdk-8-jre \
    locales \
    git \
##  mariadb client not work well
#   libmariadb-client-lgpl-dev \
    libmysqlclient-dev \
    python3 \
    python3-pip\
    && useradd -d /home/container -m container

RUN curl "http://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" -o byond.zip \
    && unzip byond.zip \
    && cd byond \
    && sed -i 's|install:|&\n\tmkdir -p $(MAN_DIR)/man6|' Makefile \
    && make install \
    && chmod 644 /usr/local/byond/man/man6/* \
    && cd .. \
    && rm -rf byond byond.zip /var/lib/apt/lists/*

FROM byond AS build
WORKDIR /tgstation

RUN apt-get install -y --no-install-recommends \
        curl

COPY . .


FROM base AS rust
RUN apt-get install -y --no-install-recommends \
        curl && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal \
    && ~/.cargo/bin/rustup target add i686-unknown-linux-gnu

FROM rust AS rust_g
WORKDIR /rust_g

RUN apt-get install -y --no-install-recommends \
        pkg-config:i386 \
        libssl-dev:i386 \
        gcc-multilib \
        git \
    && git init \
    && git remote add origin https://github.com/tgstation/rust-g

RUN pwd \
    && git fetch --depth 1 origin "${RUST_G_VERSION}" \
    && git checkout FETCH_HEAD \
    && env PKG_CONFIG_ALLOW_CROSS=1 ~/.cargo/bin/cargo build --release --target i686-unknown-linux-gnu

FROM byond

RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
        libssl1.0.0:i386 \
        zlib1g:i386

#COPY --from=build /deploy ./
COPY --from=rust_g /rust_g/target/i686-unknown-linux-gnu/release/librust_g.so ./librust_g.so

    

RUN locale-gen ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU:ru
ENV LC_ALL ru_RU.UTF-8

ENV TERM=xterm

#timezone fix
ENV TZ=Europe/Moscow
RUN ln -fs /usr/share/zoneinfo/US/Pacific-New /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata



RUN apt install zlib1g-dev libjpeg-dev libpng-dev zlib1g

#python packages
#RUN pip3 install requests Pillow
#RUN pip3 install --upgrade pip
#RUN pip3 install --upgrade pillow

RUN python3 -m pip install --upgrade pip==20.3
RUN python3 -m pip install --upgrade Pillow




USER        container
ENV         USER=container HOME=/home/container

WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh

CMD         ["/bin/bash", "/entrypoint.sh"]
