# System Configuration Module
# Handles system-wide configuration

system_configuration() {
    PrintHeader "Configuring System"
    
    # Set default username if not provided
    USERNAME=${USERNAME:-$DEFAULT_USERNAME}
    HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}
    
    # Validate timezone if not already set
    if [[ -z "$TIMEZONE" ]]; then
        echo "Available timezones (common examples):"
        echo "  America/New_York (Eastern Time)"
        echo "  America/Chicago (Central Time)" 
        echo "  America/Denver (Mountain Time)"
        echo "  America/Los_Angeles (Pacific Time)"
        echo "  Europe/London (GMT/BST)"
        echo "  Europe/Berlin (CET/CEST)"
        echo "  Asia/Tokyo (JST)"
        echo "  UTC (Coordinated Universal Time)"
        echo ""
        echo "For full list: ls /usr/share/zoneinfo/"
        
        local attempts=0
        local max_attempts=3
        
        while [[ $attempts -lt $max_attempts ]]; do
            read -p "Enter your timezone (e.g., America/New_York): " TIMEZONE
            TIMEZONE="${TIMEZONE:-UTC}"
            
            # Validate timezone exists
            if [[ -f "/usr/share/zoneinfo/$TIMEZONE" ]]; then
                break
            else
                echo "Invalid timezone: '$TIMEZONE' does not exist."
                ((attempts++))
                if [[ $attempts -lt $max_attempts ]]; then
                    echo "Please try again ($((max_attempts - attempts)) attempts remaining)"
                fi
            fi
        done
        
        if [[ $attempts -eq $max_attempts ]]; then
            PrintWarning "Maximum attempts reached. Using UTC timezone."
            TIMEZONE="UTC"
        fi
    fi
    
    # Validate username and hostname
    if [[ -n "$USERNAME" ]]; then
        if ! [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || [[ ${#USERNAME} -gt 32 ]]; then
            PrintWarning "Invalid username format. Using default: $DEFAULT_USERNAME"
            USERNAME="$DEFAULT_USERNAME"
        fi
    fi
    
    if [[ -n "$HOSTNAME" ]]; then
        if ! [[ "$HOSTNAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
            PrintWarning "Invalid hostname format. Using default: $DEFAULT_HOSTNAME"
            HOSTNAME="$DEFAULT_HOSTNAME"
        fi
    fi

    # Pass validated variables to chroot environment
    arch-chroot /mnt /bin/bash -c "
        # Set timezone using validated variable
        ln -sf '/usr/share/zoneinfo/$TIMEZONE' /etc/localtime
        hwclock --systohc

        # Configure locale
        echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
        locale-gen
        echo 'LANG=en_US.UTF-8' > /etc/locale.conf

        # Set hostname using validated variable
        echo '$HOSTNAME' > /etc/hostname

        # Configure hosts file using validated hostname
        cat > /etc/hosts << 'EOH'
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOH

        # Enable services
        systemctl enable NetworkManager

        # Create user using validated username
        useradd -m -G wheel -s /bin/zsh '$USERNAME'

        # Configure sudo
        echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers
    "

    # Set passwords non-interactively
    PrintStatus "Setting passwords..."
    SetPasswordsNonInteractive "$ROOT_PASSWORD" "$USER_PASSWORD" "$USERNAME"

    PrintStatus "System configuration completed"
}
