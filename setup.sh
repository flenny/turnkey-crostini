#!/bin/bash
# Extract image file name from path
IMAGE=$(echo ${IMAGE##*/})
IMAGE=$(echo ${IMAGE%.tar.gz})
ROOTFS=rootfs.tar.gz

# Clean working directory
rm -rf *

# Downlaod root filesystem
echo -e "\e[32mDownloading $IMAGE root filesystem...\e[0m\n"
curl http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/$IMAGE.tar.gz > $ROOTFS

# Set some variables used later on for creating the metadata files
ARCH=x86_64
OS=$(echo $IMAGE | sed 's/-[[:digit:]]*-turnkey.*//')
RELEASE=$(echo $IMAGE | grep -Po '\-([0-9].*?)\-' | tr -d '-')
APP=$(echo $IMAGE | grep -Po 'turnkey-\K[a-zA-Z0-9-]+')
VERSION=$(echo $IMAGE | grep -Po '_\K[0-9.-]+')
CDATE=$(stat -c%Y $ROOTFS)
CDATE_HR=$(stat -c '%.19y' $ROOTFS)

# Create metadata.yaml
echo -e "\e[32mCreating metadata and template files...\e[0m\n"
rm -rf templates && mkdir templates
cat << EOF > metadata.yaml
architecture: ${ARCH}
creation_date: ${CDATE}
properties:
  architecture: ${ARCH}
  description: "${OS} ${RELEASE} (${CDATE_HR}) - ${APP} (${VERSION})"
  name: ${IMAGE}
  os: ${OS}
  release: ${RELEASE}
templates:
  /etc/hostname:
    when:
      - create
      - copy
      - rename
    template: hostname.tpl
  /etc/hosts:
    when:
      - create
      - copy
      - rename
    template: hosts.tpl
EOF

# Create template files
cat << EOF > templates/hostname.tpl
${CONTAINER_NAME}
EOF

cat << EOF > templates/hosts.tpl
127.0.0.1   localhost
127.0.1.1   ${CONTAINER_NAME}
EOF

# Create metadata tarball
echo -e "\e[32mCreating metadata tarball...\e[0m\n"
tar czf metadata.tar.gz metadata.yaml templates/*
