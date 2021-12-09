#!/bin/bash

# ADJUST THESE if needed

ISO="/extradisk/vm images/OracleLinux-R8-U5-x86_64-dvd.iso"
VM_NAME=ol-test
# can also be default
# NETWORK="bridge=virbr0"
NETWORK=default

# don't adjust below

if [[ "$EUID" -ne 0 ]]; then
    echo "Must run as root"
    exit 1
fi

die() { echo "$*" 1>&2 ; exit 1; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR || die "Couldn't cd to $DIR"

# This script is for the purpose of building a test VM for RHEL
# RHEL can configure and automatically install from a kickstart file.
#
# Before doing this:
# Install the desired RH or OL system the normal way
# Look for the file /root/anaconda-ks.cfg which is generated after installation
# Edit as needed

# find my public IP to start busybox
# very rough way to do this but generally works

MY_IP=$(ip -o -4 addr list | \
	    grep eno | head -n 1  | \
	    awk '{ print $4 }' | awk -F/ '{ print $1 }')

echo "My IP address is: $MY_IP"
echo "Starting busybox httpd..."
pkill busybox
busybox httpd -p $MY_IP:8080 -h .
echo "Testing kickstart file server..."
curl -D- -s $MY_IP:8080/ks.cfg | head -n 9
echo
echo "That should have shown the first couple of lines of the ks.cfg file"
echo "If it does not, the installer will hang."

virt-install --name $VM_NAME \
	     --noreboot \
	     --memory=4096 --os-type ol8.0 \
	     --location "$ISO",initrd=isolinux/initrd.img,kernel=isolinux/vmlinuz \
	     -x "inst.ks=http://$MY_IP:8080/ks.cfg" \
	     --network $NETWORK --disk size=12

echo "VM created! now stopping busybox httpd"
pkill busybox
echo "View the VM XML definition with:"
echo "virsh dumpxml $VM_NAME"
