# Disk Management Module
# Handles disk selection, partitioning, and dual boot logic

# Function to detect available disks
detect_disk() {
    PrintHeader "Detecting Available Disks"
    
    local disks=($(lsblk -d -n -o NAME | grep -E '^[a-z]+$'))
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        HandleFatalError "No disks found"
    fi
    
    if [[ ${#disks[@]} -eq 1 ]]; then
        DISK_DEVICE="/dev/${disks[0]}"
        PrintStatus "Using single disk: $DISK_DEVICE"
    else
        PrintStatus "Available disks:"
        for i in "${!disks[@]}"; do
            echo "  $((i+1)). /dev/${disks[i]}"
        done
        
        local choice=""
        local attempts=0
        local max_attempts=3
        
        while [[ $attempts -lt $max_attempts ]]; do
            read -p "Select disk (1-${#disks[@]}): " choice
            
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#disks[@]} ]]; then
                DISK_DEVICE="/dev/${disks[$((choice-1))]}"
                break
            else
                echo "Invalid selection. Please enter a number between 1 and ${#disks[@]}."
                ((attempts++))
                if [[ $attempts -lt $max_attempts ]]; then
                    echo "Please try again ($((max_attempts - attempts)) attempts remaining)"
                fi
            fi
        done
        
        if [[ $attempts -eq $max_attempts ]]; then
            HandleValidationError "Maximum validation attempts reached for disk selection"
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
        HandleFatalError "No EFI partition found for dual boot"
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
    
    # Intelligent partition detection based on type, size, and labels
    PrintStatus "Analyzing disk partitions intelligently..."
    
    # Get detailed partition information
    local part_info=$(lsblk -rno NAME,SIZE,FSTYPE,PARTTYPE,LABEL "$DISK_DEVICE" | grep -E '[0-9]+[[:space:]]')
    
    declare -A detected_partitions
    local suggested_swap=""
    local suggested_root=""
    
    PrintStatus "Available partitions:"
    while IFS= read -r line; do
        local part_name=$(echo "$line" | awk '{print $1}')
        local part_size=$(echo "$line" | awk '{print $2}')
        local part_fstype=$(echo "$line" | awk '{print $3}')
        local part_type=$(echo "$line" | awk '{print $4}')
        local part_label=$(echo "$line" | awk '{print $5}')
        
        # Skip if this is the EFI partition (already detected)
        if [[ "$part_type" == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" ]]; then
            PrintStatus "  /dev/$part_name: EFI System Partition ($part_size) - SKIPPING"
            continue
        fi
        
        # Skip Windows partitions
        if [[ "$part_fstype" == "ntfs" ]] || [[ "$part_type" == "ebd0a0a2-b9e5-4433-87c0-68b6b72699c7" && "$part_fstype" == "ntfs" ]]; then
            PrintStatus "  /dev/$part_name: Windows partition ($part_size) - SKIPPING"
            continue
        fi
        
        # Skip Windows recovery partitions
        if [[ "$part_type" == "de94bba4-06d1-4d40-a16a-bfd50179d6ac" ]]; then
            PrintStatus "  /dev/$part_name: Windows Recovery partition ($part_size) - SKIPPING"
            continue
        fi
        
        # Skip Microsoft Reserved partitions
        if [[ "$part_type" == "e3c9e316-0b5c-4db8-817d-f92df00215ae" ]]; then
            PrintStatus "  /dev/$part_name: Microsoft Reserved partition ($part_size) - SKIPPING"
            continue
        fi
        
        # Detect suitable swap partition (Linux swap type or appropriate size)
        if [[ "$part_type" == "0657fd6d-a4ab-43c4-84e5-0933c84b4f4f" ]] || [[ "$part_fstype" == "swap" ]]; then
            PrintStatus "  /dev/$part_name: Linux swap partition ($part_size) - SUITABLE FOR SWAP"
            suggested_swap="/dev/$part_name"
        # Suggest swap for unformatted partitions of appropriate size (8-32GB range)
        elif [[ -z "$part_fstype" || "$part_fstype" == "-" ]] && [[ "$part_size" =~ ^([8-9]|[1-2][0-9]|3[0-2])(\.[0-9]+)?G$ ]]; then
            PrintStatus "  /dev/$part_name: Unformatted partition ($part_size) - SUITABLE FOR SWAP"
            if [[ -z "$suggested_swap" ]]; then
                suggested_swap="/dev/$part_name"
            fi
        # Detect suitable root partition (Linux filesystem type or large unformatted)
        elif [[ "$part_type" == "0fc63daf-8483-4772-8e79-3d69d8477de4" ]] || [[ "$part_fstype" =~ ^(ext[2-4]|xfs|btrfs)$ ]]; then
            PrintStatus "  /dev/$part_name: Linux filesystem partition ($part_size) - SUITABLE FOR ROOT"
            suggested_root="/dev/$part_name"
        # Suggest large unformatted partitions for root (>20GB)
        elif [[ -z "$part_fstype" || "$part_fstype" == "-" ]]; then
            # Extract numeric size for comparison (avoid bc dependency)
            local size_num=$(echo "$part_size" | sed 's/[^0-9.]//g')
            local size_unit=$(echo "$part_size" | sed 's/[0-9.]//g')
            
            # Simple size comparison without bc
            if [[ "$size_unit" == "T" ]] || [[ "$size_unit" == "G" && "${size_num%.*}" -ge "$MIN_ROOT_PARTITION_GB" ]]; then
                PrintStatus "  /dev/$part_name: Large unformatted partition ($part_size) - SUITABLE FOR ROOT"
                if [[ -z "$suggested_root" ]]; then
                    suggested_root="/dev/$part_name"
                fi
            else
                PrintStatus "  /dev/$part_name: Small unformatted partition ($part_size) - TOO SMALL"
            fi
        else
            PrintStatus "  /dev/$part_name: $part_fstype partition ($part_size) - UNKNOWN TYPE"
        fi
    done <<< "$part_info"
    
    # Present suggestions to user
    echo ""
    PrintStatus "Intelligent partition suggestions:"
    if [[ -n "$suggested_swap" ]]; then
        PrintStatus "Suggested SWAP partition: $suggested_swap"
    else
        PrintWarning "No suitable swap partition detected"
    fi
    
    if [[ -n "$suggested_root" ]]; then
        PrintStatus "Suggested ROOT partition: $suggested_root"
    else
        PrintWarning "No suitable root partition detected"
    fi
    
    echo ""
    local accept_suggestions=""
    local attempts=0
    local max_attempts=3
    
    while [[ $attempts -lt $max_attempts ]]; do
        read -p "Accept suggestions? (y/n): " accept_suggestions
        
        if [[ "$accept_suggestions" =~ ^[YyNn]$ ]]; then
            break
        else
            echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            ((attempts++))
            if [[ $attempts -lt $max_attempts ]]; then
                echo "Please try again ($((max_attempts - attempts)) attempts remaining)"
            fi
        fi
    done
    
    if [[ $attempts -eq $max_attempts ]]; then
        PrintWarning "Maximum attempts reached. Defaulting to manual selection."
        accept_suggestions="n"
    fi
    
    if [[ "$accept_suggestions" =~ ^[Yy] ]] && [[ -n "$suggested_swap" && -n "$suggested_root" ]]; then
        SWAP_PART="$suggested_swap"
        ROOT_PART="$suggested_root"
        PrintStatus "Using intelligent suggestions:"
        PrintStatus "Swap: $SWAP_PART"
        PrintStatus "Root: $ROOT_PART"
    else
        # Manual partition selection
        PrintStatus "Manual partition selection:"
        echo ""
        lsblk "$DISK_DEVICE"
        echo ""
        
        local manual_swap=""
        local manual_root=""
        local attempts=0
        local max_attempts=3
        
        # Validate swap partition
        while [[ $attempts -lt $max_attempts ]]; do
            read -p "Enter swap partition (e.g., /dev/nvme0n1p5): " manual_swap
            
            if [[ -b "$manual_swap" ]]; then
                break
            else
                echo "Invalid swap partition: '$manual_swap' is not a valid block device."
                ((attempts++))
                if [[ $attempts -lt $max_attempts ]]; then
                    echo "Please try again ($((max_attempts - attempts)) attempts remaining)"
                fi
            fi
        done
        
        if [[ $attempts -eq $max_attempts ]]; then
            HandleValidationError "Maximum validation attempts reached for swap partition selection"
        fi
        
        # Reset attempts for root partition
        attempts=0
        
        # Validate root partition
        while [[ $attempts -lt $max_attempts ]]; do
            read -p "Enter root partition (e.g., /dev/nvme0n1p6): " manual_root
            
            if [[ -b "$manual_root" ]]; then
                break
            else
                echo "Invalid root partition: '$manual_root' is not a valid block device."
                ((attempts++))
                if [[ $attempts -lt $max_attempts ]]; then
                    echo "Please try again ($((max_attempts - attempts)) attempts remaining)"
                fi
            fi
        done
        
        if [[ $attempts -eq $max_attempts ]]; then
            HandleValidationError "Maximum validation attempts reached for root partition selection"
        fi
        
        SWAP_PART="$manual_swap"
        ROOT_PART="$manual_root"
        PrintStatus "Using manual selection:"
        PrintStatus "Swap: $SWAP_PART"
        PrintStatus "Root: $ROOT_PART"
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
    
    # Use intelligent partition detection (same logic as GPT mode)
    PrintStatus "Analyzing disk partitions intelligently..."
    
    # Get detailed partition information
    local part_info=$(lsblk -rno NAME,SIZE,FSTYPE,PARTTYPE,LABEL "$DISK_DEVICE" | grep -E '[0-9]+[[:space:]]')
    
    local suggested_efi=""
    local suggested_swap=""
    local suggested_root=""
    
    PrintStatus "Available partitions:"
    while IFS= read -r line; do
        local part_name=$(echo "$line" | awk '{print $1}')
        local part_size=$(echo "$line" | awk '{print $2}')
        local part_fstype=$(echo "$line" | awk '{print $3}')
        local part_type=$(echo "$line" | awk '{print $4}')
        
        # Detect EFI partition
        if [[ "$part_type" == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" ]]; then
            PrintStatus "  /dev/$part_name: EFI System Partition ($part_size)"
            suggested_efi="/dev/$part_name"
        # Detect swap partition
        elif [[ "$part_type" == "0657fd6d-a4ab-43c4-84e5-0933c84b4f4f" ]] || [[ "$part_fstype" == "swap" ]]; then
            PrintStatus "  /dev/$part_name: Linux swap partition ($part_size)"
            suggested_swap="/dev/$part_name"
        elif [[ -z "$part_fstype" || "$part_fstype" == "-" ]] && [[ "$part_size" =~ ^([8-9]|[1-2][0-9]|3[0-2])(\.[0-9]+)?G$ ]]; then
            PrintStatus "  /dev/$part_name: Suitable for swap ($part_size)"
            if [[ -z "$suggested_swap" ]]; then
                suggested_swap="/dev/$part_name"
            fi
        # Detect root partition
        elif [[ "$part_type" == "0fc63daf-8483-4772-8e79-3d69d8477de4" ]] || [[ "$part_fstype" =~ ^(ext[2-4]|xfs|btrfs)$ ]]; then
            PrintStatus "  /dev/$part_name: Linux filesystem partition ($part_size)"
            suggested_root="/dev/$part_name"
        elif [[ -z "$part_fstype" || "$part_fstype" == "-" ]]; then
            local size_num=$(echo "$part_size" | sed 's/[^0-9.]//g')
            local size_unit=$(echo "$part_size" | sed 's/[0-9.]//g')
            if [[ "$size_unit" == "T" ]] || [[ "$size_unit" == "G" && "${size_num%.*}" -ge "$MIN_ROOT_PARTITION_GB" ]]; then
                PrintStatus "  /dev/$part_name: Suitable for root ($part_size)"
                if [[ -z "$suggested_root" ]]; then
                    suggested_root="/dev/$part_name"
                fi
            fi
        else
            PrintStatus "  /dev/$part_name: $part_fstype partition ($part_size)"
        fi
    done <<< "$part_info"
    
    if [[ -n "$suggested_efi" && -n "$suggested_swap" && -n "$suggested_root" ]]; then
        EFI_PART="$suggested_efi"
        SWAP_PART="$suggested_swap"
        ROOT_PART="$suggested_root"
        PrintStatus "Detected partitions:"
        PrintStatus "EFI: $EFI_PART"
        PrintStatus "Root: $ROOT_PART"
        PrintStatus "Swap: $SWAP_PART"
    else
        HandleFatalError "Could not detect all required partitions intelligently"
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
    
    # Use intelligent partition detection (same logic as other modes)
    PrintStatus "Analyzing disk partitions intelligently..."
    
    # Get detailed partition information
    local part_info=$(lsblk -rno NAME,SIZE,FSTYPE,PARTTYPE,LABEL "$DISK_DEVICE" | grep -E '[0-9]+[[:space:]]')
    
    local suggested_efi=""
    local suggested_swap=""
    local suggested_root=""
    
    PrintStatus "Available partitions:"
    while IFS= read -r line; do
        local part_name=$(echo "$line" | awk '{print $1}')
        local part_size=$(echo "$line" | awk '{print $2}')
        local part_fstype=$(echo "$line" | awk '{print $3}')
        local part_type=$(echo "$line" | awk '{print $4}')
        
        # Detect EFI partition
        if [[ "$part_type" == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" ]]; then
            PrintStatus "  /dev/$part_name: EFI System Partition ($part_size)"
            suggested_efi="/dev/$part_name"
        # Detect swap partition
        elif [[ "$part_type" == "0657fd6d-a4ab-43c4-84e5-0933c84b4f4f" ]] || [[ "$part_fstype" == "swap" ]]; then
            PrintStatus "  /dev/$part_name: Linux swap partition ($part_size)"
            suggested_swap="/dev/$part_name"
        elif [[ -z "$part_fstype" || "$part_fstype" == "-" ]] && [[ "$part_size" =~ ^([8-9]|[1-2][0-9]|3[0-2])(\.[0-9]+)?G$ ]]; then
            PrintStatus "  /dev/$part_name: Suitable for swap ($part_size)"
            if [[ -z "$suggested_swap" ]]; then
                suggested_swap="/dev/$part_name"
            fi
        # Detect root partition
        elif [[ "$part_type" == "0fc63daf-8483-4772-8e79-3d69d8477de4" ]] || [[ "$part_fstype" =~ ^(ext[2-4]|xfs|btrfs)$ ]]; then
            PrintStatus "  /dev/$part_name: Linux filesystem partition ($part_size)"
            suggested_root="/dev/$part_name"
        elif [[ -z "$part_fstype" || "$part_fstype" == "-" ]]; then
            local size_num=$(echo "$part_size" | sed 's/[^0-9.]//g')
            local size_unit=$(echo "$part_size" | sed 's/[0-9.]//g')
            if [[ "$size_unit" == "T" ]] || [[ "$size_unit" == "G" && "${size_num%.*}" -ge "$MIN_ROOT_PARTITION_GB" ]]; then
                PrintStatus "  /dev/$part_name: Suitable for root ($part_size)"
                if [[ -z "$suggested_root" ]]; then
                    suggested_root="/dev/$part_name"
                fi
            fi
        else
            PrintStatus "  /dev/$part_name: $part_fstype partition ($part_size)"
        fi
    done <<< "$part_info"
    
    if [[ -n "$suggested_efi" && -n "$suggested_swap" && -n "$suggested_root" ]]; then
        EFI_PART="$suggested_efi"
        SWAP_PART="$suggested_swap"
        ROOT_PART="$suggested_root"
        PrintStatus "Detected partitions:"
        PrintStatus "EFI: $EFI_PART"
        PrintStatus "Root: $ROOT_PART"
        PrintStatus "Swap: $SWAP_PART"
    else
        HandleFatalError "Could not detect all required partitions intelligently"
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
            HandleValidationError "Unknown dual boot mode: $DUAL_BOOT_MODE"
            ;;
    esac
    
    # Inform kernel of partition changes
    partprobe "$DISK_DEVICE"
    sleep 3
    
    PrintStatus "Disk management setup completed"
}
