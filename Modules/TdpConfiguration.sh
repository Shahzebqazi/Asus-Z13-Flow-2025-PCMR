# TDP Configuration Module
# ASUS ROG Flow Z13 (2025) - Configurable TDP and Power Management

tdp_configuration_setup() {
    PrintHeader "TDP Configuration Setup"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install TDP and power management tools
PrintStatus "Installing TDP configuration tools..."

# Install core TDP tools
pacman -S --noconfirm cpupower acpi-call-dkms msr-tools
pacman -S --noconfirm powertop turbostat i7z
pacman -S --noconfirm ryzenadj amdctl

# Create TDP management script with dynamic power management
cat > $TDP_MANAGER_PATH << EOH
#!/bin/bash
# TDP Manager for ASUS ROG Flow Z13 (2025) with Dynamic Power Management

# Function to detect charger wattage and set appropriate TDP limits
detect_charger_wattage() {
    local max_tdp=7  # Default to minimum TDP
    
    # Check USB-C charger wattage
    if [ -f /sys/class/power_supply/usb/current_max ]; then
        local current_max=$(cat /sys/class/power_supply/usb/current_max 2>/dev/null || echo "0")
        local voltage=$(cat /sys/class/power_supply/usb/voltage_now 2>/dev/null || echo "5000000")
        local wattage=$((current_max * voltage / 1000000000))
        
        if [ $wattage -ge 100 ]; then
            max_tdp=120  # Stock charger or high-wattage USB-C
        elif [ $wattage -ge 65 ]; then
            max_tdp=100  # High-wattage USB-C charger
        elif [ $wattage -ge 45 ]; then
            max_tdp=65   # Medium USB-C charger
        elif [ $wattage -ge 20 ]; then
            max_tdp=45   # Low-wattage USB-C charger
        else
            max_tdp=7    # Battery only
        fi
    fi
    
    echo $max_tdp
}

# Function to set TDP with charger-aware limits
set_tdp() {
    local requested_tdp=$1
    local max_tdp=$(detect_charger_wattage)
    
    # Limit TDP based on available power
    if [ $requested_tdp -gt $max_tdp ]; then
        echo "Requested TDP ${requested_tdp}W exceeds charger limit ${max_tdp}W. Limiting to ${max_tdp}W."
        requested_tdp=$max_tdp
    fi
    
    local tdp_mw=$((requested_tdp * 1000))
    echo "Setting TDP to ${requested_tdp}W (${tdp_mw}mW) - max available: ${max_tdp}W..."
    
    # Set TDP using ryzenadj
    if command -v ryzenadj &> /dev/null; then
        ryzenadj --stapm-limit=$tdp_mw --fast-limit=$tdp_mw --slow-limit=$tdp_mw
    fi
    
    echo "TDP set to ${requested_tdp}W successfully (charger limit: ${max_tdp}W)"
}

case "$1" in
    "efficient")
        set_tdp $TDP_EFFICIENT
        echo "Efficient power profile activated (7W TDP - minimum power consumption)"
        ;;
    "ai")
        set_tdp $TDP_AI
        echo "AI power profile activated (45W TDP, 48GB VRAM allocation)"
        ;;
    "gaming")
        set_tdp $TDP_GAMING
        echo "Gaming power profile activated (93W TDP - maximum performance with stock charger)"
        ;;
    "max")
        local max_tdp=$(detect_charger_wattage)
        set_tdp $max_tdp
        echo "Maximum power profile activated (${max_tdp}W TDP - limited by charger)"
        ;;
    "custom")
        read -p "Enter custom TDP value (7-120W): " custom_tdp
        if [[ $custom_tdp -ge 7 && $custom_tdp -le 120 ]]; then
            set_tdp $custom_tdp
            echo "Custom TDP profile activated (${custom_tdp}W TDP)"
        else
            echo "Invalid TDP value. Please enter a value between 7 and 120."
            HandleValidationError "Invalid TDP value. Please enter a value between 7 and 120."
        fi
        ;;
    "status")
        local max_tdp=$(detect_charger_wattage)
        echo "Charger detected: ${max_tdp}W maximum TDP available"
        ;;
    *)
        echo "Usage: $0 {efficient|ai|gaming|max|custom|status}"
        echo "  efficient: 7W TDP (battery optimization)"
        echo "  ai:        45W TDP (AI workloads with 48GB VRAM)"
        echo "  gaming:    93W TDP (gaming with stock charger)"
        echo "  max:       Maximum TDP based on charger (7-120W)"
        echo "  custom:    User-specified TDP (7-120W)"
        echo "  status:    Show current charger and TDP limits"
        HandleValidationError "Invalid TDP manager argument"
        ;;
esac
EOF

chmod +x $TDP_MANAGER_PATH

EOF

    PrintStatus "TDP configuration setup completed"
}
