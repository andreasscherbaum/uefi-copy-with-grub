# uefi-copy-with-grub

Copy EFI (UEFI) partition to another partition when grub updates

## Use Case

Having multiple RAID partitions, the Debian installer (don't know about other installers) will only install the UEFI files on one partition. Syncing the files to other disks is your task. The script in this repository can be hooked into `grub`, and automate this task.

## Usage

Find out which partition(s) are used for UEFI:

```
# fdisk -l /dev/sda
Disk /dev/sda: 447,13 GiB, 480103981056 bytes, 937703088 sectors
Disk model: INTEL SSDSC2KB48
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 625E2045-9BED-4A0C-9759-262C3B6C94A4

Device         Start       End   Sectors   Size Type
/dev/sda1       2048      4095      2048     1M BIOS boot
/dev/sda2       4096   1054719   1050624   513M EFI System
/dev/sda3    1054720   2031615    976896   477M Linux RAID
/dev/sda4    2031616 935624703 933593088 445,2G Linux RAID
/dev/sda5  935624704 937701375   2076672  1014M Linux RAID

# fdisk -l /dev/sdb
Disk /dev/sdb: 447,13 GiB, 480103981056 bytes, 937703088 sectors
Disk model: INTEL SSDSC2KB48
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: B548B9AC-CB03-4B0A-B358-AAC0AF4529BA

Device         Start       End   Sectors   Size Type
/dev/sdb1       2048      4095      2048     1M BIOS boot
/dev/sdb2       4096   1054719   1050624   513M EFI System
/dev/sdb3    1054720   2031615    976896   477M Linux RAID
/dev/sdb4    2031616 935624703 933593088 445,2G Linux RAID
/dev/sdb5  935624704 937701375   2076672  1014M Linux RAID
```

The partitions `/dev/sda2` and `/dev/sdb2` are the EFI partitions.

Copy the script in `templates/copy_to_boot_efi2.sh` to `/etc/grub.d/90_copy_to_boot_efi2`, add your partitions in line *9* and *10* and remove the `exit 1` in line *13* (safety measure). Then run `update-grub`. You can also run the script manually.

## Deploy using Ansible

I'm using an Ansible Playbook to deploy this script on my server:

```
- hosts: all
  become: yes
  any_errors_fatal: True
  vars:
    raid_disk_first: "sdb2"
    raid_disk_second: "sda2"
  tasks:

    - name: rsync packages
      ansible.builtin.apt:
        name:
          - rsync
        state: present

    - name: Upload copy_to_boot_efi2.sh
      ansible.builtin.template:
        src: "copy_to_boot_efi2.j2"
        dest: "/etc/grub.d/90_copy_to_boot_efi2"
        owner: "root"
        group: "root"
        mode: "0700"
```

This will replace the placeholders in `copy_to_boot_efi2.j2` and place the script in `/etc/grub.d/`. Run `update-grub` afterwards.

## More information

See this blog posting: [Install Debian Bookworm on a Software RAID and EFI](https://andreas.scherbaum.la/post/2024-07-22_install-debian-bookworm-on-a-software-raid-and-efi/).
