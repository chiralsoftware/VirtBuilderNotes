# Create an Amazon Linux 2 on-prem VM image

Amazon provides qcow2 images of its Amazon Linux 2. Unfortunately it only provides
instructions on how to install those using GUI tools, which is annoying for those
who want to do automated testing of installation on ec2 instances.

This simple script  is tested on an Ubuntu 20.04 host using virt-install.

To use it, download the Amazon Linux 2 qcow2 file from Amazon, and then
modify the eth0 interface file and the ssh key file in files,
then run the script. Within a couple of minutes the VM will be ready with the appropriate
network and SSH configuration. To destroy it, remove the created qcow2 file
and then use virsh destroy and virsh undefine. This allows rapid testing
of installng your application.
