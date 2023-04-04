# Bash Script for Provisioning Virtual Machines with KVM

This is a Github repository that contains a bash script for provisioning virtual machines with KVM. The script makes it easy for users to create virtual machines and manage them with KVM. By default, the virtual machines will be created with default configurations, but users can modify the configurations according to their needs.

## Requirements
Before using the script, make sure the following requirements are met:

- A Linux operating system that supports KVM
- KVM is installed on your system
- You have root access to your system
- You have enough hard drive space to store VM files

## Setup first

1. Make sure you installed all req bellow

```bash
# for debian, ubuntu, etc
sudo apt install genisoimage bridge-utils cpu-checker libvirt-clients libvirt-daemon libvirt-daemon-system
 qemu qemu-kvm

# for rhel, rocky, alma, etc
sudo dnf groupinstall "Virtualization Host"

# install genisoimage
sudo dnf instal genisoimage
```

2. Clone repository

```bash
git clone https://github.com/ajinfajrian/provisioning-instance_with_bash.git
```

3. Create volume pool, and image pool

```sh
mdir /data/{instance,isos}
```

4. Edit some script for your usage. :)

## How to provisioning KVM:

1. change `genvariable` with your custom resorce. (NET_NAME must format `xxx-<subnet>`. Ex. k8s-net-172.18.20)

2. set default path from volume and image pool, also custom the cloud-init in `provisioning.sh`

3. running with `bash provisioning.sh`


> Notes: if you wanna provisioning another kvm, pls backup `genvariable` file. and create another one `genvariable` file

## How to destroy kvm:

1. running `bash destroy.sh`
