#!/bin/bash

# With inspiration from:
# https://sumit-ghosh.com/posts/create-vm-using-libvirt-cloud-images-cloud-init/

echo Creating an Ubuntu 22.4 VM from scratch
echo using virt-install and cloud-init

die() { echo "$*" 1>&2 ; exit 1; }
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR || die "Couldn't cd to $DIR"

IMAGE_FILE=/var/lib/libvirt/images/$VM_NAME.img

BACKING_FILE=jammy-server-cloudimg-amd64.img

if [ ! -f $BACKING_FILE ]; then
    echo $BACKING_FILE does not exist. Downloading it...
    wget http://cloud-images.ubuntu.com/$(echo $BACKING_FILE | awk -F- '{ print $1 }')/current/$BACKING_FILE
fi


# get the image here:
# wget http://cloud-images.ubuntu.com/jammy/current/

# first create the disk image which is a copy (copy on write) of the cloud image
#qemu-img create -b $BACKING_IMAGE -f qcow2 -F qcow2 $IMAGE_FILE 10G
#virt-filesystems -a $IMAGE_FILE -lh

# The created image looks for the backing image as a relative path
# It may be easier to just copy the backing image and resize it:
cp $BACKING_FILE $IMAGE_FILE || die "couldn't copy $BACKING_IMAGE"

qemu-img resize $IMAGE_FILE +10G || die "Couldn't resize $IMAGE_FILE"

# now use the template to create a temporary file that is the cloud init
INIT_FILE=$(mktemp)
envsubst < cloud-init-network-config-template > $INIT_FILE

#echo "Finished making the init file: "
#cat $INIT_FILE
#exit 0


echo "Ignore warnings about cloud config schema errors"
# see: https://superuser.com/questions/1725127/invalid-config-for-cloud-init-but-apparently-still-works-how-do-i-remove-the

virt-install \
    --name=$VM_NAME \
    --ram=2048 \
    --vcpus=4 \
    --disk path=$IMAGE_FILE,format=qcow2 \
    --import \
    --os-variant=ubuntu22.04 \
    --network bridge=br0 \
    --cloud-init disable=on,clouduser-ssh-key=$SSH_KEY,network-config=$INIT_FILE

# removed: root-password-generate=on,
