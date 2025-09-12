#!/bin/bash

# Core Filesystem Setup for stable branch

filesystem_setup() {
    PrintHeader "Filesystem Setup"

    case "$FILESYSTEM" in
        zfs|ZFS)
            PrintWarning "ZFS path not implemented on stable core. Falling back to ext4."
            FILESYSTEM="ext4"
            ;;&
        btrfs|BTRFS)
            PrintWarning "Btrfs path not implemented on stable core. Falling back to ext4."
            FILESYSTEM="ext4"
            ;;&
        ext4|EXT4|*)
            PrintStatus "Using ext4 for root filesystem"
            ;;
    esac

    FILESYSTEM_CREATED="ext4"
    CURRENT_FILESYSTEM="ext4"
}
