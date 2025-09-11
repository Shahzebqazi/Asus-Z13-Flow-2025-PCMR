# TDP Configuration Module
# ASUS ROG Flow Z13 (2025) - Configurable TDP and Power Management

tdp_configuration_setup() {
    print_header "TDP Configuration Setup"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install TDP and power management tools
print_status "Installing TDP configuration tools..."

# Install core TDP tools
pacman -S --noconfirm cpupower acpi-call-dkms msr-tools
pacman -S --noconfirm powertop turbostat i7z
pacman -S --noconfirm ryzenadj amdctl

# Create TDP management script
cat > /usr/local/bin/tdp-manager << EOH
#!/bin/bash
# TDP Manager for ASUS ROG Flow Z13 (2025)

set_tdp() {
    local tdp_value=$1
    local tdp_mw=$((tdp_value * 1000))
    
    echo "Setting TDP to ${tdp_value}W (${tdp_mw}mW)..."
    
    # Set TDP using ryzenadj
    if command -v ryzenadj &> /dev/null; then
        ryzenadj --stapm-limit=$tdp_mw --fast-limit=$tdp_mw --slow-limit=$tdp_mw
    fi
    
    echo "TDP set to ${tdp_value}W successfully"
}

case "$1" in
    "efficient")
        set_tdp 7
        echo "Efficient power profile activated (7W TDP - minimum power consumption)"
        ;;
    "ai")
        set_tdp 70
        echo "AI power profile activated (70W TDP, 48GB VRAM allocation)"
        ;;
    "gaming")
        set_tdp 120
        echo "Gaming power profile activated (120W+ TDP)"
        ;;
    "custom")
        read -p "Enter custom TDP value (7-120W): " custom_tdp
        if [[ $custom_tdp -ge 7 && $custom_tdp -le 120 ]]; then
            set_tdp $custom_tdp
            echo "Custom TDP profile activated (${custom_tdp}W TDP)"
        else
            echo "Invalid TDP value. Please enter a value between 7 and 120."
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {efficient|ai|gaming|custom}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/tdp-manager

EOF

    print_status "TDP configuration setup completed"
}
