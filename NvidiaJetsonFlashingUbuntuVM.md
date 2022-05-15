# Installing the CoyoteCam software on the Jetson

Chiral Software, Inc. Updated May 12, 2022

## Option 1: configure a dedicated reflash laptop running Ubuntu 18.04

Install the latest Ubuntu 18.04 as usual. Note that NVidia claims the
*NVidia SDK Manager* now supports Ubuntu 20.04 as well as 18.04 but if
you do this, it will say "Linux: no available releases for Ubuntu
20.04" when attempting to flash a TX1. So do not use 20.04 or later.

Set the screen blanking to *never*.

It is recommended to use a fresh installation of Ubuntu on a computer
that is only used for that purpose. This is the easiest option but is
less convenient than having a VM. Installing the SDK on a developer
desktop or general use machine is not allowed because the SDK changes the host machine's
firewall rules.

## Option 2 (preferred): configure a VM as the reflash host 

Oracle VirtualBox can host an Ubuntu image which is capable of
reflashing, although it is sensitive to careful configuration. This section
has been tested on an Ubuntu 22.04 *host* system, although
instructions should be relevant to other host systems as well.

Install VirtualBox from the Ubuntu packages as usual.

### Add the host user to `vboxusers` group

Unless the host user is in the `vboxusers` group, VirtualBox will
always show no USB devices available:

    adduser my-username vboxusers
	
Reboot the host machine for this change to take effect. Just
restarting the VirtualBox Manager will not work.

### Configure VirtualBox manager

Start the Oracle VM VirtualBox Manager GUI tool. Before any other
actions, install the Oracle VirtualBox Extension Pack.

To
do this, go to the [downloads
site](https://www.virtualbox.org/wiki/Downloads) and select the
*VirtualBox 6.x Oracle VM VirtualBox Extension Pack* for all supported
platforms. Download it, and then in VirtualBox manager, go to File /
Preferences / Extensions and add the Oracle VM VirtualBox Extension
Pack. It's ok if the VNC extension is already there. This extension is
necessary to be able to access host physical USB devices from the
guest VM.

### Create VM

From the Oracle VM VirtualBox Manager, click *New*. Choose a name for
the VM, such as Jetson Flash VM. Select the type of *Linux* and the
version of *Ubuntu (64 bit)*.

Set memory to 16384 MB. The minimum requirement of the SDK is is 8192,
but 16 gb is recommended.

On the hard disk screen, select *Create a virtual hard disk
now*. Click create and choose *VDI (VirtualBox Disk Image)*. Either
dynamically allocated or fixed size can be used. If the host machine
has a very large disk, fixed size is reasonable. Choose a size of
100gb or more, to not run out of space when using the SDK.

Go to the settings of the new VM instance, and set the atest 18.04
desktop ISO as the optical disk. In System / Processor, select 2 to 4
CPUs for better performance. Under USB, enable the USB controller and
select USB 3.0. Without USB 3.0 it will not work.

### Define USB filters

Filters must be defined. Still within VM settings / USB, click the the
new filter tool (above the add filter tool). Define two
filters, specific for the the TX1:

| Filter name      | Vendor ID | Product ID | All other fields |
|------------------|-----------|------------|------------------|
| NVidia Recovery  | `0955`    | `7721`     | blank            |
| NVidia USB Ether | `0955`    | `7020`     | blank            |

If some other NVidia device has another product ID, add the
corresponding filter.

### Install the OS, update and install guest add-ons

Install the OS image, which is Ubuntu 18.04 Desktop, as usual. For
convenience, allow login without a password, and pick a very short
user password.

After installing the OS, perform an update and install the `build-essential` package. This
is necessary so the guest add-ons installation will work. Also turn
off screen blanking in Settings / Power. After
`build-essential` is installed in the guest, reboot and then use Devices / Insert Guest
Additions CD Image to activate the guest extensions. These will better
integrate file transfer, shared clipboard and other features.

# Install the NVidia components

All the following will occur on the reflash computer, whether a
physical machine or a VM.

Download from the NVidia [developer
site](https://developer.nvidia.com/nvidia-sdk-manager). You will need
an NVidia developer password. Install from DEB file and start the
SDK manager. The manager will require the NVidia login.

The Target Hardware button will be available. Select either the TX1 or
TX2. The Target Operating System for the TX1 will be JetPack 4.6.2 or
later.

Continue to Step 2. It will ask to create a folder
`~/Downloads/nvidia/sdkm_downloads`. Allow it to create this folder.

## Reflash the Jetson

1. Power off the Jetson.
1. Connect to the control USB.
1. Press and hold the Force Recovery button. Press and release the
   Power button. Wait one moment and then release Force Recovery
   button. The four buttons on the lower left are labeled `RST`,
   `VOL` and `REC`. The power button is labeled `POWERBTN` to the
   right and bottom of the power button. The `REC` button is the force
   recovery button, so the buttons to use are the third button
   (recovery) and the fourth (power).
1. (Optional) Confirm that the NVidia is in recovery mode and USB is
   being passed through to the VM. Open a terminal and run `lsusb` to see that the
   Jetson is active. The result will indicate an interface `0955:771
   NVidia Corp.` If `lsusb` does not show the NVidia device, it means
   that USB filters are not configured, or the NVidia device is not in
   recovery mode, or the cable isn't working.
1. Within the SDK, the window will say *SDK Manager is about to flash
   your Jetson TX1 module*. Choose *Manual Setup - Jetson TX1*. Select
   OEM Configuration: *Pre-Config*. For username and password, enter
   `jetson` and `jetson`. The Target Hardware should have correctly
   identified the Jetson TX1 or TX2.
1. Press *Flash* and let it flash. If it can't detect the TX1, try
   rebooting the computer and re-powering the Jetson and repeating
   from the beginning of the process.
1. After it flashes, it will then come up into the OS and have an
   operating system. The SDK Manager will display *SDK Manager is
   about to install the SDK components on your Jetson TX1 module*.
   The OS will connect to the host computer by using
   USB as an Ethernet and will assign the host computer an IP of
   192.168.55.100, and the Jetson .1. Use the same username and
   password assigned earlier.  Click
   *Install*. The connection attempt will repeat several times
   automatically, as it will not succeed until the Jetson USB network
   comes up.
1. The SDK will complete installing various other components.
1. Log in to the Jetson by SSH: `ssh jetson@192.168.55.1` and perform
   updates and other installation tasks.

# Common problems with setting up VirtualBox and flashing

The user must be added to the `vboxusers` group or no USB devices will
be available in the VM manager.

The Oracle VirtualBox extensions must be installed or USB devices will not be
detected.

The USB type in the VM instance settings must be set to USB 3.0 or Ubuntu 18.04 will not work
properly with USB.

USB filters must be defined to automatically pass through physical USB
devices to the VM, or else it will get to 99% and then
hang. Dynamically connecting the USB device will not work.

It would seem that defining one overall USB filter with just the
vendor ID 0955 would work, but doing that results in the host taking
the USB connection before the guest filter can take it, and will
result in the same hang at 99%.

The VM must be configured to have a minimum of two CPUs and 16gb of
RAM, or performance will be poor. The VM's disk should be 100gb or
larger.

Use the official NVidia USB cables. If these are not available, use a
high quality cable. Be extremely gentle with the management USB port
on the carrier board. It is very fragile. Touch the ground on the
Jetson board before touching any other component on the board.

# Network notes

## IP forwarding to allow the Jetson to access the network

*Do this after flash has completed and after a reboot.* The reason is
to not save the iptables definitions which the SDK sets up. Reboot,
and then perform this configuration.

The NVidia SDK will modify the host `ip-tables` and forwarding rules
so that the Jetson can connect to external websites to download
packages. This works fine inside a VM that itself is connected to a
virtual Ethernet interface. However this modification is not
stored. After rebooting the flashing machine, verify that the network
changes have not persisted:

    # sysctl net.ipv4.ip_forward
    net.ipv4.ip_forward = 0

`iptables` will also not list any rules in the forwarding chain:

    # iptables -t nat -L

All chains will be empty.

To enable forwarding, set both the kernel forwarding parameter, and
add a NAT rule to `iptables`:

    # sysctl -w net.ipv4.ip_forward=1
    net.ipv4.ip_forward = 1
	# iptables -t nat -A POSTROUTING -o  enp0s3  -j MASQUERADE

Now the Jetson will have access to the network. The specification of
`enp0s3` in the `iptables` command is necessary, or else it will try
to NAT packets on ALL its interfaces, which will block external
connectivity of the VM.

## Making IP forwarding changes persistent

Ubuntu 18.04 network configuration is quite different from modern
Ubuntu and other systems, so follow these instructions.

### Enable kernel network forwarding

Edit the `/etc/sysctl.conf` file and
enable IPv4 forwarding by uncommenting the relevant line:

    net.ipv4.ip_forward=1

### Enable persistent iptables definitions

Next install the `iptables-persistent` package using `apt install
iptables-persistent`. This package converts currently active
`iptables` rules into persistent files. After adding the rule to the
NAT table using the `iptables` command above, save the IPv4
rules. This is done during package installation, so if the NAT rule is
in place before the package is installed, it should be saved,
otherwise use:

    # iptables-save > /etc/iptables/rules.v4

This rules file will be processed on startup to restore the NAT rule,
and any other rules that were saved. Note that other versions of
`iptables-save` take a `-f` command line option to specify the
file. The version with Ubuntu 18.04 does not support this, and IO
redirect should be used.

Verify that forwarding is in place by observing the following line in
`/etc/iptables/rules.v4` within the `*nat` section:

    -A POSTROUTING -o enp0s3 -j MASQUERADE

Now, the Jetson will be able to reach the outside
network and this change will persist through reboots.

### Allowing SSH to the guest and the Jetson

We can set up so that the Jetson, connected by USB to the flash VM,
can be reached directly by SSH from the host VM. This makes using
Ansible convenient. We will do this in two steps: first enable
connection to the guest VM by SSH, and then add ability to connect
directly from the host machine to the Jetson by SSH.

### Enable port forwarding to connect to the guest VM by SSH

In the Oracle VM VirtualBox Manager, to go the VM instance settings /
Network / Advanced. Click *Porting Forwarding*. Add a rule:

| Name            | Protocol | Host IP   | Host Port | Guest IP  | Guest Port |
|-----------------|----------|-----------|-----------|-----------|------------|
| SSH to guest VM | TCP      | 127.0.0.1 | 2222      | 10.0.2.15 | 22         |

Make sure OpenSSH server is installed in the guest VM:

    apt install -y openssh-server
	
Now it is possible to connect to the VM by SSH. From the host machine,
using the user name defined when installing Ubuntu on the guest:

	ssh my-username@127.0.0.1 -p 2222

### Port forwarding to connect from host machine to Jetson by SSH 

Now to configure direct SSH connection from the host, or even outside
the host, to the Jetson. This will be done by first allowing
connections from the host to the guest, and then having a PREROUTING
rule on the guest to forward traffic to the Jetson. It will also need
a TCP ESTABLISHED connections rule.

Go back to the VM instance settings / Network
/ Advanced / Port Forwarding and add another rule:

| Name          | Protocol | Host IP   | Host Port | Guest IP  | Guest Port |
|---------------|----------|-----------|-----------|-----------|------------|
| SSH to Jetson | TCP      | 127.0.0.1 | 2022      | 10.0.2.15 | 2022       |

(Note that the Host IP could actually be the external IP address of the
host machine, which would make the Jetson reachable on the host's
external IP. This could be very useful if there is an Ansible
installer on the same LAN, for example.)

Now on the guest VM, add a forwarding rule:

	iptables -A PREROUTING -t nat  -i enp0s3  -p tcp --dport 2022 -j DNAT --to-destination 192.168.55.1:22
    iptables -A FORWARD -i enp0s12u2i5 -o enp0s3 -m state --state ESTABLISHED,RELATED -j ACCEPT

This will forward incoming port 2022, on the guest, to the Jetson's
port 22. SSH will now work from the host machine directly to the
Jetson:

    ssh jetson@localhost -p 2022

This will allow easy control of the Jetson from the host
machine. Another possible configuration is to use a bridged interface
to give the Jetson an interface on the host machine's LAN.

Make these changes persistent if needed:

    # iptables-save > /etc/iptables/rules.v4

If flashing several Jetsons, or re-installing the guest VM, there will
be warnings about changed SSH host keys for the same domain
name. To avoid these, use the following SSH options on the command
line:

    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

Or create a file `localhost` in `/etc/ssh/ssh_config.d`:

    Host localhost
        StrictHostKeyChecking=no
	    UserKnownHostsFile=/dev/null

# Installing application on the Jetson

Now that the flashing system is working and the Jetson has been
flashed, we can install the application. All commands as root. If port
forwarding is configured as above, SSH can be directly from the host
machine.

## Free up storage space on the Jetson

The SDK installs too much on the Jetson. Remove unnecessary packages
and then use clear out the contents of `/var/cache/apt`:

    apt remove -y thunderbird libreoffice-*
	apt purge -y gnome-shell ubuntu-wallpapers-bionic chromium-browser* 
	apt autoremove
    apt clean

and save 2.8gb of storage. 

Remove large static libraries which are not needed for running:

    rm /etc/alternatives/libcudnn_stlib \
      /usr/lib/aarch64-linux-gnu/libcudnn_static*.a \
	  /usr/lib/aarch64-linux-gnu/libnvinfer_static.a
	  
This saves another 1gb.

See [this
reference](https://dev.to/ajeetraina/how-i-cleaned-up-jetson-nano-disk-space-by-40-b9h)
for background on saving space on the Jetson.
