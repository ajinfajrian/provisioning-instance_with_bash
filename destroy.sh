#!/bin/bash
VOLUME_POOL=/data/instance
IMAGE_POOL=/data/isos

#parse data from source.txt
while read line; do
  #check if line contains NAME
  if [[ $line == NAME=* ]]; then
    NAME=${line#*=}
    NAME=${NAME//\"}
    MAC=$(randmac -q)
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

    MAC_EXIST=$( virsh net-dumpxml $NET_NAME | grep $IP |  grep -o -E ..:..:..:..:..:..)
    printf "\n=========== Delete Static IP = $IP ============\n"
    virsh net-update $NET_NAME delete ip-dhcp-host --xml  "<host mac='$MAC_EXIST' name='$NAME' ip='$IP'/>" --live --config
    virsh net-update $NET_NAME delete dns-host "<host ip='$IP'><hostname>$NAME</hostname></host>" --config --live

    printf "\n=========== Destroy & Remove instance $NAME ============\n \n"
    virsh destroy --domain $NAME
    virsh undefine --domain $NAME
    rm -rf $VOLUME_POOL/$NAME

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
    unset MAC_EXIST
  fi
done < genvariable
