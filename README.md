# Creating VMs quickly and painlessly in Ubuntu and using bridged networks

This guide is an update of an earler guide which was based on the
`virt-builder` command. The `virt-builder` command is no longer the
best way to quickly build an Ubuntu VM. The better approach with
Ubuntu 22.04 and later is to use the `virt-intall` command.

# Establish bridge networking host configuration (Ubuntu 22.04 host)

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
            enp1s0:
                addresses:
                - 128.32.43.202/24
                gateway4: 128.32.43.1
                nameservers:
                    addresses:
                    - 8.8.8.8
        version: 2

Note that the interface name in the VM instance will depend on the
particular backing image. `enp1s0` is the correct interface in Ubuntu
cloud images.

# Cloud init

Ubuntu supports a method called cloud init to configure users, network
and other features. One way to use cloud init is to create CDROM ISO
files with the parameter. Fortunately the `virt-install` command
handles this automatically so only a few options are needed.

`disable=on` disables cloud init after first boot.

`clouduser-ssh-key=$SSH_KEY` imports the given public key to the
default user. The default user is named `ubuntu`.

`network-config=cloud-init-network-config` uses the
`cloud-init-network-config` file. An example of this file is included.

# Putting it together

Look at the example in `vm-script.sh` and
`cloud-init-network-config`. 
