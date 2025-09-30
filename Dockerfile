# Dockerfile to clone and compile the Linux kernel
# Usage:
#   docker build --build-arg BUILD_TYPE=default --build-arg TARGET_ARCH=arm64 -t linux-kernel-build .
#   docker build --build-arg BUILD_TYPE=full --build-arg TARGET_ARCH=x86_64 -t linux-kernel-build .
#   docker build --build-arg BUILD_TYPE=allyesconfig --build-arg TARGET_ARCH=arm64 -t linux-kernel-build .
#   docker build --build-arg BUILD_TYPE=default --build-arg TARGET_ARCH=riscv --build-arg DOCKER_PLATFORM=linux/riscv64 -t linux-kernel-build .

ARG DOCKER_PLATFORM=linux/arm64
FROM --platform=${DOCKER_PLATFORM} ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_TYPE=default
ARG TARGET_ARCH=arm64

ENV ARCH=${TARGET_ARCH}

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git build-essential libncurses-dev bison flex libssl-dev libelf-dev bc wget ca-certificates \
    rsync kmod cpio python3 python3-dev pahole && \
    rm -rf /var/lib/apt/lists/*

# Clone Linux kernel source
WORKDIR /usr/src
RUN git clone --depth=1 https://github.com/torvalds/linux.git
WORKDIR /usr/src/linux


# Build kernel based on argument and print compile time
RUN if [ "$BUILD_TYPE" = "full" ]; then \
      make ARCH=${TARGET_ARCH} defconfig && \
      echo "Starting full kernel build..." && \
      START=$(date +%s) && \
      make ARCH=${TARGET_ARCH} -j$(nproc) && \
      END=$(date +%s) && \
      echo "Full kernel build time: $((END-START)) seconds"; \
    elif [ "$BUILD_TYPE" = "allyesconfig" ]; then \
      make ARCH=${TARGET_ARCH} allyesconfig && \
      echo "Starting allyesconfig kernel build..." && \
      START=$(date +%s) && \
      make ARCH=${TARGET_ARCH} -j$(nproc) && \
      END=$(date +%s) && \
      echo "Allyesconfig kernel build time: $((END-START)) seconds"; \
    else \
      make ARCH=${TARGET_ARCH} tinyconfig && \
      echo "Starting tiny kernel build..." && \
      START=$(date +%s) && \
      make ARCH=${TARGET_ARCH} -j$(nproc) && \
      END=$(date +%s) && \
      echo "Tiny kernel build time: $((END-START)) seconds"; \
    fi

CMD ["bash"]
