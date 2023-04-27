#!/bin/bash

# With inspiration from:
# https://sumit-ghosh.com/posts/create-vm-using-libvirt-cloud-images-cloud-init/

echo Creating an Ubuntu 22.4 VM from scratch
echo using virt-install and cloud-init

IMAGE_FILE=build.img
VM_NAME=build
BACKING_IMAGE=jammy-server-cloudimg-amd64.img
UBUNTU_NAME=$(echo $BACKING_IMAGE | awk -F- '{ print $1 }')
SSH_KEY=~/.ssh/id_rsa.pub

if [ ! -f $BACKING_FILE ]; then
    echo $BACKING_FILE does not exist. Downloading it...
    wget http://cloud-images.ubuntu.com/$UBUNTU_NAME/current/
fi


# get the image here:
# wget http://cloud-images.ubuntu.com/jammy/current/

# first create the disk image which is a copy (copy on write) of the cloud image
#qemu-img create -b $BACKING_IMAGE -f qcow2 -F qcow2 $IMAGE_FILE 10G
#virt-filesystems -a $IMAGE_FILE -lh

# The created image looks for the backing image as a relative path
# It may be easier to just copy the backing image and resize it:
TMP_IMAGE=$(mktemp --suffix=.img)
cp $BACKING_IMAGE $TMP_IMAGE
qemu-img resize $TMP_IMAGE +10G
truncate -r $TMP_IMAGE $IMAGE_FILE
virt-resize--expand /dev/sda1 $TMP_IMAGE $IMAGE_FILE
rm $TMP_IMAGE
virt-filesystems -a $IMAGE_FILE -lh

virt-install \
    --name=$VM_NAME \
    --ram=2048 \
    --vcpus=4 \
    --disk path=$IMAGE_FILE,format=qcow2 \
    --import \
    --os-variant=ubuntu22.04 \
    --network bridge=br0 \
    --cloud-init disable=on,clouduser-ssh-key=$SSH_KEY,network-config=cloud-init-network-config

# removed: root-password-generate=on,
