#!/bin/bash
VOLUME_POOL=/data/vms
IMAGE_POOL=/data/isos


PRE_NET_NAME=$(cat ./genvariable | grep NET_NAME | tr -d 'NET_NAME=' | uniq )
NET_SUB=$(echo $PRE_NET_NAME | tr -dc '0-9,.')
ID_NET=$(echo $((RANDOM % 9000 + 1000)))

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
    qemu-img convert -O qcow2 $IMAGE_POOL/$NAME_IMAGE $VOLUME_POOL/$NAME/vda.qcow2
    #qemu-img convert -f raw -O qcow2 $IMAGE_POOL/$NAME_IMAGE $VOLUME_POOL/$NAME/vda.qcow2

    #resize root disk
    qemu-img resize $VOLUME_POOL/$NAME/vda.qcow2 $DISK"G"

    cat > $VOLUME_POOL/$NAME/user-data << EOF
#cloud-config
timezone: Asia/Jakarta
users:
  - name: ubuntu
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEhUOyfx7af+pTR/lmb3nwp/ghYOl6eEDRq7H7HWVhIprlsDhlqRwD87RXetSK9b1JBWV8DjWo0H/IZql2nPO+IrYCVkuz5Soqy9oo9rCCrHsmOmBqYneFCVe/4st7nAWLSXgyobjoQ/8yFhnxpYepUWVRE5wiyNnkF67M/Kz74I4qLeuZQDlvoaL2VK6gc8zJ83G5iQj/qi9Gd4b2y/SuRT2PcIZv+2NJtnSyt8so99UT16vU6GBsDsbm28GiMeEUES5lVbaavHn0mlHPwOX20d4Ca1365iIjhLbHf1n3SN9I5MQWi8jK4VBhIIXfBLobOmR9LQW0CJJnfkbkUhxB root@ahmadazharrivaldy
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
EOF
    #create meta-data for cloud-init
    echo "instance-id: $NAME" > $VOLUME_POOL/$NAME/meta-data
    echo "local-hostname: $NAME" >> $VOLUME_POOL/$NAME/meta-data
  
    genisoimage  -output $VOLUME_POOL/$NAME/cloud-init.iso -volid cidata -joliet -rock $VOLUME_POOL/$NAME/user-data $VOLUME_POOL/$NAME/meta-data
    
    #create instance

    printf "\n =========== Create Instance $NAME ============ \n\n"
    virt-install --name $NAME \
    --ram $RAM \
    --vcpus $CPU \
    --disk $VOLUME_POOL/$NAME/vda.qcow2,format=qcow2 \
    --disk $VOLUME_POOL/$NAME/cloud-init.iso,device=cdrom \
    --network network=$NET_NAME,mac=$MAC \
    --graphics none \
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
