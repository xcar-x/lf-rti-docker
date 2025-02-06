# SPDX-FileCopyrightText: (c) 2025 Xronos Inc.
# SPDX-License-Identifier: BSD-3-Clause

# syntax=docker/dockerfile:1

# image from which all other stages derive
ARG BASEIMAGE=ubuntu:noble-20241118.1
ARG BUILDKIT_SBOM_SCAN_CONTEXT=false

##################
# dependencies stage
##################
FROM ${BASEIMAGE} AS build-dependencies
ARG BUILDKIT_SBOM_SCAN_STAGE=false

USER root
SHELL ["/bin/bash", "-c"]

# configure debian and terminal for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo -e '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d

# install utilities
RUN apt-get update -q
RUN apt-get install -y -q --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg2 \
        lsb-release \
        wget 
RUN git config --global advice.detachedHead false

# install common build tools
RUN apt-get install -y -q --no-install-recommends \
        gcc \
        clang \
        clang-format \
        libc-dev \
        libssl-dev \
        make \
        musl-dev \
        openssl

# cmake
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
        | gpg --dearmor - \
        | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/kitware.list >/dev/null
RUN apt-get update -q 
RUN apt-get install -y -q --no-install-recommends \
        cmake

##################
# build stage
##################
FROM build-dependencies AS build
ARG BUILDKIT_SBOM_SCAN_STAGE=false
ARG RTI_GIT_REF=4f183a4
ARG RTI_USE_SSL=OFF

USER root
SHELL ["/bin/bash", "-c"]

# build RTI
WORKDIR /app
RUN git clone -q https://github.com/lf-lang/reactor-c
WORKDIR /app/reactor-c
RUN git checkout ${RTI_GIT_REF}
WORKDIR /app/reactor-c/core/federated/RTI
RUN mkdir -p cmake
WORKDIR /app/reactor-c/core/federated/RTI/cmake
RUN cmake \
        -DAUTH=${RTI_USE_SSL} \
        -DCMAKE_BUILD_TYPE=Release \
        ..
RUN make
RUN make install


###################
# application stage
###################
FROM ${BASEIMAGE} AS app
ARG BUILDKIT_SBOM_SCAN_STAGE=true
ARG RTI_GIT_REF=4f183a4
ARG RTI_USE_SSL=OFF

LABEL org.opencontainers.image.title="Xronos Lingua Franca RTI Distribution"
LABEL org.opencontainers.description="Xronos distribution of Lingua Franca RTI"
LABEL org.opencontainers.image.vendor="Xronos Inc"
LABEL org.opencontainers.image.authors="Jeff C. Jensen <11233838+elgeeko1@users.noreply.github.com>"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"
LABEL org.opencontainers.image.version="reactor-c-${RTI_GIT_REF}"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/xronosinc/rti"
LABEL org.opencontainers.image.source="https://github.com/xronos-inc/lf-rti-docker"

EXPOSE 15045/tcp

USER root
SHELL ["/bin/bash", "-c"]

RUN [ "${RTI_USE_SSL}" = "OFF" ] \
    || (apt-get update -q \
        && apt-get install -y -q --no-install-recommends openssl \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* )

COPY --from=build /usr/local/bin/RTI /usr/local/bin/RTI

# copy license files and third-party notifications
COPY third-party-licenses /third-party-licenses/
RUN ln -s /third-party-licenses /home/ubuntu/third-party-licenses
COPY LICENSE /
COPY THIRD_PARTY_NOTICE /
RUN ln -s /LICENSE /home/ubuntu/
RUN ln -s /THIRD_PARTY_NOTICE /home/ubuntu/

USER ubuntu
WORKDIR /home/ubuntu
SHELL ["/bin/bash", "-c"]

ENTRYPOINT ["/usr/local/bin/RTI"]
