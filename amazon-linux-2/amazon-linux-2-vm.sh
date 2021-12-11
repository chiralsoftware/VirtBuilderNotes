#!/bin/bash

echo Creating an Amazon VM

VM_NAME=amazon-vm

if [[ "$EUID" -ne 0 ]]; then
    echo "Must run as root"
    exit 1
fi

die() { echo "$*" 1>&2 ; exit 1; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR || die "Couldn't cd to $DIR"

rm -f amazon-image.qcow2
cp amzn2-kvm-2.0.20211201.0-x86_64.xfs.gpt.qcow2 amazon-image.qcow2 || die "you need to have the amazon qcow2 image"

virt-install --name $VM_NAME --memory 4096 --disk amazon-image.qcow2 --import --os-variant rhel7.0 --wait 1

virsh list
echo "The amazon VM should be running now. Stopping it so the password can be set."
virsh destroy $VM_NAME
#echo "Changing the password"
# changing the password isn't needed - just use the SSH key to log in
#virt-customize -a amazon-image.qcow2  --password ec2-user:password:hello
echo "Injecting an SSH key, setting network and turning off cloud init"

virt-customize -a amazon-image.qcow2 \
	       --copy-in files/99-disable-network-config.cfg:/etc/cloud/cloud.cfg.d \
	       --copy-in files/ifcfg-eth0:/etc/sysconfig/network-scripts \
	       --ssh-inject ec2-user:file:files/ec2-user-key 
#	       --selinux-relabel

echo "Done. Start the VM with:"
echo "virsh start $VM_NAME"
