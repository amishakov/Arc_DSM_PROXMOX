#!/bin/bash
#
# Script name: tdsm.sh
# Author: Aleksey Mishakov
# Website: https://github.com/amishakov
# Date: 11 March, 2025
# Purpose: Automatic creation of Proxmox VM 8.3+ using Arc Loader for DSM 7+.
#

set -e

# Ask for VMID
read -p "Enter Virtual Machine ID for Synology DSM install: " VMID

# Check if VMID already exists
if qm status $VMID &> /dev/null
then
    read -p "VM $VMID already exists. Do you want to remove it? (y/n) " choice
    case "$choice" in
        y|Y )
            qm stop $VMID
            qm destroy $VMID
            echo "VM $VMID has been removed."
            ;;
        * )
            echo "Please enter a different VMID."
            exit 1
            ;;
    esac
fi

# Download and extract Arc image
wget https://download.umbrel.com/release/1.4.0/umbrelos-amd64.img.xz
unxz umbrelos-amd64.img.xz
cp umbrelos-amd64.img /var/lib/vz/template/iso/
rm umbrelos-amd64.img

# Create virtual machine
qm create "$VMID" \
 --name DSM7 \
 --memory 4096 \
 --sockets 1 \
 --cores 4 \
 --cpu host \
 --net0 e1000,bridge=vmbr0 \
 --ostype l26 \
 --bios seabios \
 --boot order=sata0

# Import Arc image as boot disk
image="/var/lib/vz/template/iso/umbrelos-amd64.img"
qm importdisk "$VMID" "$image" local --format raw
qm set $VMID --sata0 local:$VMID/vm-$VMID-disk-0.raw

# Start the virtual machine
# qm start "$VMID"
