#!/bin/bash
#
# Script name: install_arx_dsm.sh
# Author: Alexey Mishakov
# Website: omnical.ru
# Date: 23 November, 2026
# Purpose: Automatic creation of Proxmox VM using Arx Loader for DSM 7+.
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
version=$(curl -s https://api.github.com/repos/AuxXxilium/arx/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
newversion=${version:1}
 
# Construct download URL using latest release version
url="https://github.com/AuxXxilium/arx/releases/download/$version/arx-$version.vmdk-dyn.zip"

# Download and extract Arx image
wget $url
image_folder="/var/lib/vz/template/iso/"
unzip "arx-$version.vmdk-dyn.zip" -d $image_folder
rm "arx-$version.vmdk-dyn.zip"

# Create virtual machine
qm create "$VMID" --name ARXDSM --memory 4096 --sockets 1 --cores 2 --cpu host --net0 virtio,bridge=vmbr0 --ostype l26

# Import Arx image as boot disk
image="/var/lib/vz/template/iso/arx-dyn.vmdk"
qm importdisk "$VMID" "$image" local
qm set "$VMID" -sata0 local:vm-$VMID-disk-0
qm set "$VMID" --boot c --bootdisk sata0

# Add a new SATA disk to the virtual machine
qm set "$VMID" --sata1 volume02:32

# Start the virtual machine
qm start "$VMID"
