# =============================================================================
# TaaOS Builder Container - Torvalds Edition (FIXED)
# =============================================================================
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Update and Upgrade
RUN apt-get update && apt-get upgrade -y

# PHASE 1: ISO Build Deps
RUN apt-get install -y --no-install-recommends \
    live-build \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools

# PHASE 2: Kernel Build Deps (UPDATED WITH FIXES)
# Added: debhelper, libdw-dev, python3-dev, pahole, rsync
RUN apt-get install -y --no-install-recommends \
    git \
    build-essential \
    libncurses-dev \
    gawk \
    flex \
    bison \
    openssl \
    libssl-dev \
    dkms \
    libelf-dev \
    libudev-dev \
    pciutils \
    ibutils \
    bc \
    rsync \
    kmod \
    cpio \
    debhelper \
    libdw-dev \
    python3-dev \
    dwarves

# Utils (including dos2unix for Windows CRLF fix)
RUN apt-get install -y --no-install-recommends \
    curl \
    wget \
    sudo \
    ca-certificates \
    dos2unix

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set Workdir
WORKDIR /build

CMD ["/bin/bash"]