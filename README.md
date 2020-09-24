# Creating VMs quickly and painlessly in Ubuntu and using bridged networks

Ubuntu comes with many options for creating and managing VMs. Sometimes there are too many options. The goal 
of this guide is to show how to create VMs quickly and doing everything from the command line, without
having to use a windowing system.

This guide assumes libguestfs-tools is installed.

# Creating the VM disk image

Use the virt-builder tool to create the VM disk image in qcow2 format:

    virt-builder ubuntu-18.04 --format qcow2 \
    --output test-ubuntu.qcow2 --hostname test-ubuntu \
    --firstboot-command 'systemctl enable serial-getty@ttyS0.service; systemctl start serial-getty@ttyS0.service' \
    --root-password password:root

This command will create a qcow2 image. The important thing here is that it enables the serial console and sets an easy root password
so that logging in and configuring it will be easy.

# Create an XML file for the VM

    virt-install --name test-ubuntu --import --ram 4096 --disk test-ubuntu.qcow2 --print-xml

This will print out a simple XML file for the VM with minimal configuration. Edit if needed. Save this to a file.

# Define the VM

Use virsh define with the XML:

    virsh define /path/to/vm.xml

Start it:

    virsh start test-ubuntu

# Connect to console

Now from a shell, connect to the console without needing a windowing system:

    virsh console test-ubuntu

Proceed to use the VM.

# Unconfiguring it if necessary

    virsh undefine test-ubuntu

This removes the XML definition but does not delete the storage. Confirm this by listing:

    virsh list --all

# Bridge networking host configuration (Ubuntu 20.04 host)

On the host machine, if the existing netplan looks like this:

    network:
      ethernets:
        eno1:
          addresses:
          - 128.32.42.201/24
          gateway4: 128.32.42.1
          nameservers:
            addresses:
            - 8.8.8.8
      version: 2

Change it to be as follows:

    network:
      version: 2
      ethernets:
        eno1:
          dhcp4: false
      bridges:
        br0:
          interfaces: [eno1]
          dhcp4: false
          addresses:
          - 128.32.42.201/24
          gateway4: 128.32.42.1
          nameservers:
            addresses:
            - 8.8.8.8

# Bridge networking guest configuration

The guest will see its IP interface as normal:

    network:
        ethernets:
            enx001060316cae:
                addresses:
                - 173.198.59.55/28
                gateway4: 173.198.59.49
                nameservers:
                    addresses:
                    - 209.18.47.61
        version: 2

This could be configured from within the virt-builder command too
