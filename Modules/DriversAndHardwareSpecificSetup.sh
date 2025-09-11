# Drivers and Hardware Specific Setup Module
# ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+ Specific Drivers and I/O Setup

drivers_and_hardware_setup() {
    PrintHeader "Z13 Flow 2025 Drivers and Hardware Setup"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install AMD Strix Halo specific drivers
PrintStatus "Installing AMD Strix Halo drivers..."

# AMD GPU drivers with verification
InstallPackageGroupWithVerification mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon chroot

# Install MediaTek Wi-Fi drivers (MT7925e) with verification
PrintStatus "Installing MediaTek Wi-Fi drivers..."
InstallPackageGroupWithVerification linux-firmware-mtk iw wpa_supplicant wireless_tools chroot

# Install audio drivers with verification
PrintStatus "Installing audio drivers..."
InstallPackageGroupWithVerification alsa-utils pulseaudio pulseaudio-alsa pavucontrol chroot

# Install touchpad and input drivers with verification
PrintStatus "Installing input drivers..."
InstallPackageGroupWithVerification xf86-input-libinput xf86-input-synaptics xorg-xinput chroot

# Install USB and I/O drivers with verification
PrintStatus "Installing USB and I/O drivers..."
InstallPackageGroupWithVerification usbutils usb_modeswitch thunderbolt chroot

# Install camera drivers with verification
PrintStatus "Installing camera drivers..."
InstallPackageGroupWithVerification v4l-utils cheese chroot

# Install Bluetooth drivers with verification
PrintStatus "Installing Bluetooth drivers..."
InstallPackageGroupWithVerification bluez bluez-utils blueman chroot

# Install additional hardware support with verification
PrintStatus "Installing additional hardware support..."
InstallPackageGroupWithVerification lm_sensors hdparm smartmontools acpi acpid chroot

# Display stability fixes and 180Hz support
PrintStatus "Configuring display stability and 180Hz support..."
cat > /etc/X11/xorg.conf.d/20-amdgpu.conf << 'EOF'
Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
    Option "DRI" "3"
    Option "TearFree" "true"
    Option "VariableRefresh" "true"
    Option "EnablePageFlip" "true"
    Option "AccelMethod" "glamor"
EndSection

Section "Monitor"
    Identifier "eDP-1"
    Option "PreferredMode" "1920x1200@180.00"
    Option "TargetRefresh" "180"
EndSection

Section "Screen"
    Identifier "Screen0"
    Monitor "eDP-1"
    Device "AMD"
    SubSection "Display"
        Modes "1920x1200@180.00" "1920x1200@120.00" "1920x1200@60.00"
    EndSubSection
EndSection
EOF

# Configure Wayland for better variable refresh rate support
PrintStatus "Configuring Wayland for variable refresh rate..."
cat > /etc/environment << 'EOF'
# Enable Wayland for better variable refresh rate support
XDG_SESSION_TYPE=wayland
WLR_DRM_NO_MODIFIERS=1
WLR_DRM_DEVICES=/dev/dri/card0
EOF

EOF

    PrintStatus "Z13 Flow 2025 drivers installation completed"
}
