#!/bin/bash
# Change working directory; script location || home directory
if (( $EUID != 0 )); then SUDO='sudo'; fi

# Install packages
$SUDO apt install -y wget

# Get raw image file name
echo -e "\n#################################"
echo -e "#                               #"
echo -e "#  Welcome to \e[94mtu\e[91mrn\e[93mkey\e[0m-\e[94mcr\e[92mos\e[91mti\e[94mni\e[0m  #"
echo -e "#                               #"
echo -e "#################################\n"
read -p "TurnKey image name: " IMAGE
IMAGE=$(echo ${IMAGE##*/})
IMAGE=$(echo ${IMAGE%.tar.gz})

OS=$(echo $IMAGE | sed 's/-[[:digit:]]*-turnkey.*//')
RELEASE=$(echo $IMAGE | grep -Po '\-([0-9].*?)\-' | tr -d '-')
APP=$(echo $IMAGE | grep -Po 'turnkey-\K[a-zA-Z0-9-]+')
VERSION=$(echo $IMAGE | grep -Po '_\K[0-9.-]+')

# Read container name
read -p "Container name [$APP]: " CONTAINER_NAME
CONTAINER_NAME=${CONTAINER_NAME:-$APP}
echo $CONTAINER_NAME > container_name

# Downlaod root filesystem
echo -e "\e[92mDownloading $IMAGE.tar.gz...\e[0m"
wget -q --show-progress http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/$IMAGE.tar.gz -O rootfs.tar.gz

CDATE=$(stat -c%Y rootfs.tar.gz)
CDATE_HR=$(stat -c '%.19y' rootfs.tar.gz)

# Create metadata.yaml
echo -e "\e[92mCreating metadata and template files...\e[0m"
rm -rf templates && mkdir templates
cat << EOF > metadata.yaml
architecture: x86_64
creation_date: ${CDATE}
properties:
  architecture: x86_64
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
127.0.0.1   ${CONTAINER_NAME}
EOF

# Create metadata tarball
echo -e "\e[92mCreating metadata tarball...\e[0m"
tar czf metadata.tar.gz metadata.yaml templates/*
