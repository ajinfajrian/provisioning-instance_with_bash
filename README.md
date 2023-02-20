# provisioning-instance_with_bash

## How to provisioning kvm:

1. change `genvariable` with your custom resorce

2. set default path from volume and image pool, also custom the cloud-init in `provisioning.sh`

3. running with `bash provisioning.sh`


** Notes: if you wanna provisioning another kvm, pls backup `genvariable` file. and create another one `genvariable` file

## How to destroy kvm:

1. running `bash destroy.sh`
