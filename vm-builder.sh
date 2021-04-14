#!/bin/bash

# DEFINE THESE VALUES FOR THE VM TO BE CREATED.
# This is based on a static IP for bridged networking.
# For other configurations, modify the netplan file.

# These three values must be changed:
IP_ADDRESS="128.32.43.201/24"
GATEWAY="128.32.43.1"
HOSTNAME="new-server"

# These values don't need to be changed if you want to use the defaults:
FIRST_USER=admin
FIRST_PASSWORD=password
# size is ignored for now - there is some bug in virtbuilder
SIZE=15G


# Changes below here are not necessary

# MUST BE ROOT

if [[ "$EUID" -ne 0 ]]; then
    echo "Please run as root"
    exit 1
fi

die() { echo "$*" 1>&2 ; exit 1; }

# IP MUST NOT ALREADY BE IN USE

IP=$(echo $IP_ADDRESS | sed 's/\/[0-9]*$//')

ping -W 1 -c 3 $IP
if [ $? -eq 0 ]; then
    echo "IP address: $IP is up. Don't create a VM for this IP without making sure it's ok to delete the existing VM first!"
    exit 1
fi

IMAGE_PATH="/var/lib/libvirt/images/$HOSTNAME"

# IMAGE FILE MUST NOT ALREADY EXIST

if [ -d "$IMAGE_PATH" ] 
then
    echo "Server image path: $IMAGE_PATH exists. Delete it before continuing using this command:"
    echo
    echo "rm -r $IMAGE_PATH"
    exit 1
fi

# VM MUST NOT BE DEFINED ALREADY

virsh dominfo $HOSTNAME &> /dev/null
if [ $? -eq 0 ]; then
    echo "virsh dominfo $HOSTNAME succeeded, so that domain is already defined. Undefine the domain"
    echo "using this command:"
    echo
    echo "virsh undefine $HOSTNAME"
    exit 1
fi

mkdir $IMAGE_PATH || die "Couldn't make directory: $IMAGE_PATH"

NETPLAN="# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      addresses:
        - $IP_ADDRESS
      gateway4: $GATEWAY
      nameservers:
        addresses:
          - 8.8.8.8
"

# NOW RUN virt-builder TO CREATE THE DISK

# There's another thing called virt-install that makes an image from pacakges,
# but virt-builder is faster becasue it uses pre-built packages
# See: https://developer.fedoraproject.org/tools/virt-builder/about.html for the difference
virt-builder  ubuntu-20.04 --update --format qcow2 --hostname $HOSTNAME \
	      --output $IMAGE_PATH/server.qcow2 \
	      --install emacs,yaml-mode \
	      --write /etc/netplan/01-netcfg.yaml:"$NETPLAN" \
	      --firstboot-command "useradd --shell /bin/bash -m -p '' --groups sudo $FIRST_USER; echo $FIRST_USER:$FIRST_PASSWORD | chpasswd; chage -d0 $FIRST_USER" \
	      --root-password locked:disabled || die "Failed to run virt-builder!"

# the size setting is giving an error now for some reason
#	      --size $SIZE

# IF YOU WANT TO ENABLE CONSOLE

# If you want console to be active on this, add:
# 	      --firstboot-command 'systemctl enable serial-getty@ttyS0.service; systemctl start serial-getty@ttyS0.service'
# to the virt-builder command. Console is not enabled by default because SSH will work.

# About passwords and login: the virt-builder instructions show how to create a user without a password.
# However that's not a good option because ssh by default doesn't allow empty
# passwords. And we don't want to change the config of ssh to be less
# secure, so better to just create a user with a placeholder password.
# The command chage -d0 could be added to force the user to change password first time
# The initial useradd command sets the password to the empty string which is not a valid encrypted password
# but it is immediately changed by the chpasswd command
	      
echo "Now creating and defining the XML"

# A cool trick from:
# https://www.reddit.com/r/VFIO/comments/9sqfty/does_virshs_create_subcommand_support_having_the/

# NOW DEFINE THE VM

virt-install --name $HOSTNAME --import --ram 4096 --disk  $IMAGE_PATH/server.qcow2 \
	     --print-xml  | virsh define /dev/stdin

if [ $? -ne 0 ]; then
    echo "Defining the VM failed."
    exit 1
fi

# WE ARE DONE

echo
echo "The VM is defined. Now it can be started with:"
echo
echo "virsh start $HOSTNAME"
echo
#echo " and you can connect on console with:"
#echo
#echo "virsh console $HOSTNAME"
echo "Connect with:"
echo "ssh $FIRST_USER@$IP"
echo
