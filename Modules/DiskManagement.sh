# Disk Management Module
# Handles disk selection, partitioning, and dual boot logic

# Function to detect available disks
detect_disk() {
    PrintHeader "Detecting Available Disks"
    
    local disks=($(lsblk -d -n -o NAME | grep -E '^[a-z]+$'))
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        PrintError "No disks found"
        exit 1
    fi
    
    if [[ ${#disks[@]} -eq 1 ]]; then
        DISK_DEVICE="/dev/${disks[0]}"
        PrintStatus "Using single disk: $DISK_DEVICE"
    else
        PrintStatus "Available disks:"
        for i in "${!disks[@]}"; do
            echo "  $((i+1)). /dev/${disks[i]}"
        done
        
        read -p "Select disk (1-${#disks[@]}): " choice
        if [[ $choice -ge 1 && $choice -le ${#disks[@]} ]]; then
            DISK_DEVICE="/dev/${disks[$((choice-1))]}"
        else
            PrintError "Invalid selection"
            exit 1
        fi
    fi
    
    PrintStatus "Selected disk: $DISK_DEVICE"
}

# Function to detect existing partitions
detect_existing_partitions() {
    PrintStatus "Detecting existing partitions..."
    
    # Look for EFI partition
    EFI_PART=$(lsblk -rno NAME,PARTTYPE "$DISK_DEVICE" | grep -i "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | cut -d' ' -f1)
    if [[ -n "$EFI_PART" ]]; then
        EFI_PART="/dev/$EFI_PART"
        PrintStatus "Found EFI partition: $EFI_PART"
    fi
    
    # Check for Windows partitions
    local windows_part=$(lsblk -rno NAME,FSTYPE "$DISK_DEVICE" | grep -i "ntfs" | head -1 | cut -d' ' -f1)
    if [[ -n "$windows_part" ]]; then
        PrintStatus "Found Windows partitions"
        WINDOWS_EXISTS=true
    else
        PrintStatus "No Windows partitions found"
        WINDOWS_EXISTS=false
    fi
}

# Function to setup dual boot GPT mode
setup_dual_boot_gpt() {
    PrintHeader "Setting up Dual Boot (GPT UEFI)"
    
    if [[ -z "$EFI_PART" ]]; then
        PrintError "No EFI partition found for dual boot"
        exit 1
    fi
    
    PrintStatus "Using existing EFI partition: $EFI_PART"
    
    # Find free space for Linux
    PrintStatus "Looking for free space for Linux installation..."
    
    # Use cgdisk for partitioning
    PrintStatus "Starting cgdisk for partitioning..."
    PrintWarning "Please create partitions manually:"
    PrintWarning "1. Create a Linux root partition in free space"
    PrintWarning "2. Create a Linux swap partition (equal to RAM size)"
    PrintWarning "3. Do NOT modify existing Windows or EFI partitions"
    
    read -p "Press Enter when ready to start cgdisk..."
    cgdisk "$DISK_DEVICE"
    
    # Detect new partitions
    partprobe "$DISK_DEVICE"
    sleep 2
    
    # Find the new partitions
    local new_parts=$(lsblk -rno NAME "$DISK_DEVICE" | grep -E '[0-9]+$' | sort -V | tail -2)
    local part_array=($new_parts)
    
    if [[ ${#part_array[@]} -ge 2 ]]; then
        SWAP_PART="/dev/${part_array[0]}"
        ROOT_PART="/dev/${part_array[1]}"
        PrintStatus "Detected partitions:"
        PrintStatus "Swap: $SWAP_PART"
        PrintStatus "Root: $ROOT_PART"
    else
        PrintError "Could not detect new partitions"
        exit 1
    fi
}

# Function to setup dual boot new mode
setup_dual_boot_new() {
    PrintHeader "Setting up Dual Boot (New EFI)"
    
    PrintStatus "Creating new EFI setup for dual boot..."
    
    # Use cgdisk for partitioning
    PrintStatus "Starting cgdisk for partitioning..."
    PrintWarning "Please create partitions manually:"
    PrintWarning "1. Create EFI partition (512MB, type EF00)"
    PrintWarning "2. Create Windows partition (size as needed, type 0700)"
    PrintWarning "3. Create Linux root partition (size as needed, type 8300)"
    PrintWarning "4. Create Linux swap partition (equal to RAM size, type 8200)"
    
    read -p "Press Enter when ready to start cgdisk..."
    cgdisk "$DISK_DEVICE"
    
    # Detect partitions
    partprobe "$DISK_DEVICE"
    sleep 2
    
    # Find partitions
    local parts=$(lsblk -rno NAME "$DISK_DEVICE" | grep -E '[0-9]+$' | sort -V)
    local part_array=($parts)
    
    if [[ ${#part_array[@]} -ge 4 ]]; then
        EFI_PART="/dev/${part_array[0]}"
        ROOT_PART="/dev/${part_array[2]}"
        SWAP_PART="/dev/${part_array[3]}"
        PrintStatus "Detected partitions:"
        PrintStatus "EFI: $EFI_PART"
        PrintStatus "Root: $ROOT_PART"
        PrintStatus "Swap: $SWAP_PART"
    else
        PrintError "Could not detect all required partitions"
        exit 1
    fi
}

# Function to setup single boot
setup_single_boot() {
    PrintHeader "Setting up Single Boot"
    
    PrintStatus "Creating single boot setup..."
    
    # Use cgdisk for partitioning
    PrintStatus "Starting cgdisk for partitioning..."
    PrintWarning "Please create partitions manually:"
    PrintWarning "1. Create EFI partition (512MB, type EF00)"
    PrintWarning "2. Create Linux root partition (rest of disk, type 8300)"
    PrintWarning "3. Create Linux swap partition (equal to RAM size, type 8200)"
    
    read -p "Press Enter when ready to start cgdisk..."
    cgdisk "$DISK_DEVICE"
    
    # Detect partitions
    partprobe "$DISK_DEVICE"
    sleep 2
    
    # Find partitions
    local parts=$(lsblk -rno NAME "$DISK_DEVICE" | grep -E '[0-9]+$' | sort -V)
    local part_array=($parts)
    
    if [[ ${#part_array[@]} -ge 3 ]]; then
        EFI_PART="/dev/${part_array[0]}"
        ROOT_PART="/dev/${part_array[1]}"
        SWAP_PART="/dev/${part_array[2]}"
        PrintStatus "Detected partitions:"
        PrintStatus "EFI: $EFI_PART"
        PrintStatus "Root: $ROOT_PART"
        PrintStatus "Swap: $SWAP_PART"
    else
        PrintError "Could not detect all required partitions"
        exit 1
    fi
}

# Main disk management function
disk_management_setup() {
    PrintHeader "Disk Management Setup"
    
    # Detect disk
    detect_disk
    
    # Detect existing partitions
    detect_existing_partitions
    
    # Setup based on dual boot mode
    case "$DUAL_BOOT_MODE" in
        "gpt")
            setup_dual_boot_gpt
            ;;
        "new")
            setup_dual_boot_new
            ;;
        "none")
            setup_single_boot
            ;;
        *)
            PrintError "Unknown dual boot mode: $DUAL_BOOT_MODE"
            exit 1
            ;;
    esac
    
    # Inform kernel of partition changes
    partprobe "$DISK_DEVICE"
    sleep 3
    
    PrintStatus "Disk management setup completed"
}
