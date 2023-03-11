#!/bin/bash
VOLUME_POOL=/data/instance
IMAGE_POOL=/data/isos

#parse data from source.txt
while read line; do
  #check if line contains NAME
  if [[ $line == NAME=* ]]; then
    NAME=${line#*=}
    NAME=${NAME//\"}
    MAC=$(date +%s | md5sum | head -c 6 | sed -e 's/\([0-9A-Fa-f]\{2\}\)/\1:/g' -e 's/\(.*\):$/\1/' | sed -e 's/^/52:54:00:/')
  fi

  #check if line contains CPU
  if [[ $line == CPU=* ]]; then
    CPU=${line#*=}
  fi

  #check if line contains RAM
  if [[ $line == RAM=* ]]; then
    RAM=${line#*=}
  fi

  #check if line contains DISK
  if [[ $line == DISK=* ]]; then
    DISK=${line#*=}
  fi

  #check if line contains IP
  if [[ $line == IP=* ]]; then
    IP=${line#*=}
  fi

  #check if line contains NET_NAME
  if [[ $line == NET_NAME=* ]]; then
    NET_NAME=${line#*=}
    NET_INT=$(virsh net-info --network $NET_NAME | awk '{print $2}' | grep vi)
  fi

  #check if line contains NAME_IMAGE
  if [[ $line == NAME_IMAGE=* ]]; then
    NAME_IMAGE=${line#*=}
  fi

  #provisioning instance with parsed data
  if [[ -n $NAME && -n $CPU && -n $RAM && -n $DISK && -n $IP && -n $NET_NAME && -n $NAME_IMAGE ]]; then
    #create instance directory
    printf "\n =========== Provisioning Instance $NAME =============== \n\n"
    mkdir -p $VOLUME_POOL/$NAME

    #convert base image to root disk
    printf "\n =========== Convert Cloud Image ============ \n \n"
    #qemu-img convert -O qcow2 $IMAGE_POOL/$NAME_IMAGE $VOLUME_POOL/$NAME/vda.qcow2
    qemu-img convert -f raw -O qcow2 $IMAGE_POOL/$NAME_IMAGE $VOLUME_POOL/$NAME/vda.qcow2

    #resize root disk
    qemu-img resize $VOLUME_POOL/$NAME/vda.qcow2 $DISK"G"

    cat > $VOLUME_POOL/$NAME/user-data << EOF
#cloud-config
timezone: Asia/Jakarta
users:
  - name: ajinha
    ssh-authorized-keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/jpMd00hSkXILXNNvzic+PERIvou28UikpR7ayqgxo ed25519_04/04/2
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
write_files:
  - path: /etc/cloud/templates/hosts.debian.tmpl
    content: |
      192.168.122.11 k3s-master-1 master-1
      192.168.122.12 k3s-master-2 master-2
      192.168.122.13 k3s-master-3 master-3

      192.168.122.21 k3s-worker-1 worker-1
      192.168.122.22 k3s-worker-2 worker-2
      192.168.122.50 k3s-addons

      192.168.122.100 k3s-vip

EOF

    #create meta-data for cloud-init
    echo "instance-id: $NAME" > $VOLUME_POOL/$NAME/meta-data
    echo "local-hostname: $NAME" >> $VOLUME_POOL/$NAME/meta-data
    
    # cloud-localds not supported on rhel, rocky, alma.
    # cloud-localds -v $VOLUME_POOL/$NAME/cloud-init.iso $VOLUME_POOL/$NAME/user-data $VOLUME_POOL/$NAME/meta-data
    
    genisoimage  -output /kvm/instance/$NAME/cloud-init.iso -volid cidata -joliet -rock /kvm/instance/$NAME/user-data /kvm/instance/$NAME/meta-data
    
    printf "\n =========== Configure Network =========== \n\n"
    virsh net-update $NET_NAME add ip-dhcp-host --xml "<host mac='$MAC' name='$NAME' ip='$IP'/>" --live --config
    virsh net-update $NET_NAME add dns-host "<host ip='$IP'><hostname>$NAME</hostname></host>" --config --live


    #create instance

    printf "\n =========== Create Instance $NAME ============ \n\n"
    virt-install --name $NAME \
    --ram $RAM \
    --vcpus $CPU \
    --disk $VOLUME_POOL/$NAME/vda.qcow2,format=qcow2 \
    --disk $VOLUME_POOL/$NAME/cloud-init.iso,device=cdrom \
    --network network=$NET_NAME,mac=$MAC \
    --graphics none \
    --osinfo detect=on,require=off \
    --import \
    --noautoconsole


    #remove cloud-init iso
    #rm $VOLUME_POOL/$NAME/cloud-init.iso

    #unset parsed data
    unset NAME
    unset CPU
    unset RAM
    unset DISK
    unset IP
    unset NET_NAME
    unset NET_INT
    unset NAME_IMAGE
    unset MAC
  fi
done < genvariable
