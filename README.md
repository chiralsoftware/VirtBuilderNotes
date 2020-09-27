# Creating VMs quickly and painlessly in Ubuntu and using bridged networks

Ubuntu comes with many options for creating and managing VMs. Sometimes there are too many options. The goal 
of this guide is to show how to create VMs quickly and doing everything from the command line, without
having to use a windowing system. Even better, this guide will create a script which creates and defines a VM
in a single step which is accessible by SSH immediately, with no console or GUI tools needed.

This entire guide removes the need to click around in `virt-manager` or similar tools.

This guide assumes libguestfs-tools is installed.

# Creating the VM disk image

Use the virt-builder tool to create the VM disk image in qcow2 format:

    virt-builder ubuntu-18.04 --format qcow2 \
    --output test-ubuntu.qcow2 --hostname test-ubuntu \
    --update \
    --install emacs \
    --size 15G \
    --firstboot-command 'systemctl enable serial-getty@ttyS0.service; systemctl start serial-getty@ttyS0.service' \
    --root-password password:root

This command will create a qcow2 image. 

The `--firstboot-command` option enables the serial console so we can connect to it with `virsh console` later. This avoids
any step that needs a windowing system.

The root password is also set so that login is easy. It should be changed before network is activated. If the root
password is not specified a random password will be generated.

### Caching and speed

By default virt-builder will cache the template image files in `~/.cache/virt-builder`. This makes creating new VMs fast.
Building the VM with the `--update` and `--install` options makes it considerably slower, taking about 90 seconds more. 
With a cached image, and without `--update` or `--install`, building a VM
takes about 30 seconds. To get a list of the available templates, use `virt-builder --list`. As of this time, there isn't yet an Ubuntu 20.04 template.

# Create an XML file for the VM

    virt-install --name test-ubuntu --import --ram 4096 --disk test-ubuntu.qcow2 --print-xml > path/to/vm.xml

This will print out a simple XML file for the VM with minimal configuration. Edit if needed. Save this to a file.

The disk image should be placed in a directory in `/var/lib/libvirt/images` . Specify the disk path correctly with the `--disk` parameter
and then the XML will be ready to use.

# Define the VM

Use virsh define with the XML:

    virsh define /path/to/vm.xml

Start it:

    virsh start test-ubuntu

# Connect to console

Now from a shell, connect to the console without needing a windowing system:

    virsh console test-ubuntu

Proceed to use the VM. Network configuration will be needed.

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
            ens3:
                addresses:
                - 128.32.43.202/24
                gateway4: 128.32.43.1
                nameservers:
                    addresses:
                    - 8.8.8.8
        version: 2

Within the sample script, we use the `--write` command to automatically set those values during installation.

# Users with empty passwords and ssh: problems in first login

The `virt-builder` instructions recommend using this command to set up a user with no password, and the user
is forced to change password on first login:

    --firstboot-command 'useradd -m -p "" rjones ; chage -d 0 rjones'

The problem with this is that by default ssh doesn't allow empty password logins so this user can't log in except on console,
and ideally we would go straight into an SSH session. We could change the ssh config to allow login with empty password,
but then we have to not forget to take an additional step to change the ssh configuration after first login.

The solution is to specify a non-empty password:

    --firstboot-command "useradd --shell /bin/bash -m -p '' --groups sudo admin; echo admin:mypassword | chpasswd; chage -d0 admin" 

This will create an admin user with a non-empty password which must be changed on first login, and can be set by ssh.

# Putting it all together

Look at the included vm-builder script to see a working example that does it all in one script, creating a VM
with correct static IPs and ready to access by SSH.

# Upon first login

Copy over your SSH key using `ssh-copy-id` and then edit and set:

    PasswordAuthentication no

Also run any updates and enable the firewall.
