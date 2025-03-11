#!/bin/bash
#
# Script name: pve-dsm.sh
# Author: King Tam
# Website: https://kingtam.eu.org
# Date: July 7, 2023
# Purpose: Automatic creation of DSM VM on Proxmox VE.
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

# Check if unzip is installed, install if not
if ! command -v unzip &> /dev/null; then
    echo "unzip could not be found, installing..."
    apt install unzip -y
fi

# Get latest release version from GitHub API
version=$(curl -s https://api.github.com/repos/fbelavenuto/arpl/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
newversion=${version:1}

# Construct download URL using latest release version
url="https://github.com/fbelavenuto/arpl/releases/download/$version/arpl-$newversion.img.zip"

# Download and extract arpl image
wget $url
image_folder="/var/lib/vz/template/iso/"
unzip "arpl-$newversion.img.zip" -d $image_folder
rm "arpl-$newversion.img.zip"


# Create virtual machine
qm create "$VMID" --name DSM --memory 4096 --sockets 1 --cores 2 --cpu host --net0 virtio,bridge=vmbr0 --ostype l26

# Import arpl image as boot disk
image="/var/lib/vz/template/iso/arpl.img"
qm importdisk "$VMID" "$image" local-lvm
qm set "$VMID" -sata0 local-lvm:vm-$VMID-disk-0
qm set "$VMID" --boot c --bootdisk sata0

# Add a new SATA disk to the virtual machine
qm set "$VMID" --sata1 volume02:32

# Start the virtual machine
qm start "$VMID"
