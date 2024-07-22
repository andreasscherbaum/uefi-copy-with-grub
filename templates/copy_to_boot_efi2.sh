#!/bin/bash

set -e # abort on error
set -u # abort on variable not set
#set -x # trace execution

# one or both devices can already be mounted, potentially with a label and not with the device name

device_first="/dev/sda2" # FIXME: replace with your partition name and number
device_second="/dev/sdb2" # FIXME: replace with your partition name and number

# FIXME: remove the following exit once you setup the above partitions
exit 1

# the findmnt will fail when the device is not mounted, that is expected
set +e
mountpoint_first=`/usr/bin/findmnt --first-only --noheadings --output=TARGET ${device_first}`
mountpoint_second=`/usr/bin/findmnt --first-only --noheadings --output=TARGET ${device_second}`
set -e


if [ -z "${mountpoint_first}" ];
then
    # not mounted, create the mount point
    path_first="/efi-first"
    /usr/bin/mkdir "${path_first}"
    echo "No existing mount point found for ${device_first}"
    echo "  Mounting on ${path_first}"
    # and mount the decive
    /usr/bin/mount "${device_first}" "${path_first}"
else
    # already mounted, use the existing mount point
    path_first="${mountpoint_first}"
    echo "Found existing mount point ${mountpoint_first} for device ${device_first}"
fi

if [ -z "${mountpoint_second}" ];
then
    # not mounted, create the mount point
    path_second="/efi-second"
    /usr/bin/mkdir "${path_second}"
    echo "No existing mount point found for ${device_second}"
    echo "  Mounting on ${path_second}"
    # and mount the decive
    /usr/bin/mount "${device_second}" "${path_second}"
else
    # already mounted, use the existing mount point
    path_second="${mountpoint_second}"
    echo "Found existing mount point ${mountpoint_second} for device ${device_second}"
fi

if [ ! -d "${path_first}/EFI" -a -d "${path_second}/EFI" ];
then
    # there's an "EFI" directory in the second mount point,
    # but not in the first one - this is wrong, and will damage
    # the installation once rsync runs
    echo "There is no 'EFI' directory in the first (source) mount point!"
    echo "But there is an 'EFI' directory in the second (destination) mount point!"
    echo "This will not work, possibly switch the devices!"
    echo "Source: ${device_first} (mounted on: ${path_first})"
    echo "Destination: ${device_second} (mounted on: ${path_second})"
    exit 1
fi


#echo "rsync --dry-run --verbose --times --recursive --delete \"${path_first}/\" \"${path_second}/\""
#rsync --dry-run --verbose --times --recursive --delete "${path_first}/" "${path_second}/"
rsync --verbose --times --recursive --delete "${path_first}/" "${path_second}/"


if [ -z "${mountpoint_first}" ];
then
    # unmount the device
    /usr/bin/umount "${path_first}"
    # remove the directory
    /usr/bin/rmdir "${path_first}"
fi

if [ -z "${mountpoint_second}" ];
then
    # unmount the device
    /usr/bin/umount "${path_second}"
    # remove the directory
    /usr/bin/rmdir "${path_second}"
fi

exit 0
