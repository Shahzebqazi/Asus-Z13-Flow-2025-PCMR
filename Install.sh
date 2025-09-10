#!/bin/bash

# Install.sh - Configurable Arch Linux Installation Script for ASUS ROG Flow Z13
# Author: sqazi
# Version: 1.0.0
# Date: September 10, 2025

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
INSTALL_DESKTOP=""
INSTALL_GAMING=""
INSTALL_POWER_MGMT=""
DUAL_BOOT=""
ENABLE_SNAPSHOTS=""
DISK_DEVICE=""
USERNAME=""
HOSTNAME=""
TIMEZONE=""

# Installation state tracking
INSTALLATION_STARTED=false
ZFS_POOL_CREATED=false
BASE_SYSTEM_INSTALLED=false

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to prompt user for configuration
configure_installation() {
    print_header "ASUS ROG Flow Z13 Arch Linux Installation Configuration"
    
    echo "This script will install Arch Linux with optimizations for:"
    echo "• Maximum performance when plugged in"
    echo "• Efficient power management and battery life"
    echo "• Hassle-free laptop and tablet use"
    echo ""
    
    # Disk selection
    print_status "Available disks:"
    lsblk -d -o NAME,SIZE,MODEL
    echo ""
    
    while true; do
        read -p "Enter the disk device (e.g., nvme0n1): " DISK_DEVICE
        if [[ -z "$DISK_DEVICE" ]]; then
            print_error "Disk device cannot be empty. Please try again."
            continue
        fi
        
        # Remove /dev/ prefix if user included it
        DISK_DEVICE="${DISK_DEVICE#/dev/}"
        
        # Validate disk exists
        if [[ ! -b "/dev/$DISK_DEVICE" ]]; then
            print_error "Disk /dev/$DISK_DEVICE does not exist. Please check the device name."
            continue
        fi
        
        # Confirm disk selection
        print_warning "You selected: /dev/$DISK_DEVICE"
        read -p "Is this correct? (y/n): " confirm_disk
        if [[ $confirm_disk == "y" || $confirm_disk == "Y" ]]; then
            DISK_DEVICE="/dev/$DISK_DEVICE"
            break
        fi
    done
    
    # Dual boot configuration
    echo ""
    read -p "Do you want to preserve Windows for dual-boot? (y/n): " DUAL_BOOT
    
    # User configuration
    echo ""
    
    # Username validation
    while true; do
        read -p "Enter username: " USERNAME
        if [[ -z "$USERNAME" ]]; then
            print_error "Username cannot be empty. Please try again."
            continue
        fi
        if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            print_error "Username must start with lowercase letter or underscore and contain only lowercase letters, numbers, hyphens, and underscores."
            continue
        fi
        break
    done
    
    # Hostname validation
    while true; do
        read -p "Enter hostname: " HOSTNAME
        if [[ -z "$HOSTNAME" ]]; then
            print_error "Hostname cannot be empty. Please try again."
            continue
        fi
        if [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]; then
            print_error "Hostname must start and end with alphanumeric characters and contain only alphanumeric characters and hyphens."
            continue
        fi
        break
    done
    
    # Timezone validation
    while true; do
        read -p "Enter timezone (e.g., America/New_York): " TIMEZONE
        if [[ -z "$TIMEZONE" ]]; then
            print_error "Timezone cannot be empty. Please try again."
            continue
        fi
        if [[ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]]; then
            print_warning "Timezone '$TIMEZONE' not found. Common timezones:"
            print_warning "America/New_York, America/Los_Angeles, Europe/London, Asia/Tokyo"
            read -p "Continue with this timezone anyway? (y/n): " continue_tz
            if [[ $continue_tz == "y" || $continue_tz == "Y" ]]; then
                break
            fi
            continue
        fi
        break
    done
    
    # Desktop environment
    echo ""
    echo "Desktop Environment Options:"
    echo "1) Omarchy (Tiling window manager - default, optimized for Z13)"
    echo "2) XFCE (Lightweight, user-friendly - recommended for new users)"
    echo "3) i3 (Tiling window manager - advanced users)"
    echo "4) GNOME (Modern desktop environment)"
    echo "5) KDE Plasma (Feature-rich desktop)"
    echo "6) Minimal (No desktop environment)"
    read -p "Choose desktop environment (1): " desktop_choice
    
    case $desktop_choice in
        1) INSTALL_DESKTOP="omarchy" ;;
        2) INSTALL_DESKTOP="xfce" ;;
        3) INSTALL_DESKTOP="i3" ;;
        4) INSTALL_DESKTOP="gnome" ;;
        5) INSTALL_DESKTOP="kde" ;;
        6) INSTALL_DESKTOP="minimal" ;;
        *) INSTALL_DESKTOP="omarchy" ;;
    esac
    
    # Gaming setup
    echo ""
    read -p "Install gaming setup (Steam, Proton, GameMode)? (y/n): " INSTALL_GAMING
    
    # Power management
    echo ""
    read -p "Install advanced power management (asusctl, TLP)? (y/n): " INSTALL_POWER_MGMT
    
    # Snapshots
    echo ""
    read -p "Enable ZFS snapshots for system recovery? (y/n): " ENABLE_SNAPSHOTS
    
    # Confirmation
    echo ""
    print_header "Installation Summary"
    echo "Disk: $DISK_DEVICE"
    echo "Dual-boot: $DUAL_BOOT"
    echo "Username: $USERNAME"
    echo "Hostname: $HOSTNAME"
    echo "Timezone: $TIMEZONE"
    echo "Desktop: $INSTALL_DESKTOP"
    echo "Gaming: $INSTALL_GAMING"
    echo "Power Management: $INSTALL_POWER_MGMT"
    echo "Snapshots: $ENABLE_SNAPSHOTS"
    echo ""
    
    read -p "Proceed with installation? (y/n): " confirm
    if [[ $confirm != "y" ]]; then
        print_error "Installation cancelled."
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if running in UEFI mode
    if [[ ! -d /sys/firmware/efi ]]; then
        print_error "System is not booted in UEFI mode. Please boot in UEFI mode."
        print_warning "To fix this:"
        print_warning "1. Restart your computer"
        print_warning "2. Enter BIOS/UEFI settings (usually F2, F12, or Del during boot)"
        print_warning "3. Enable UEFI mode and disable Legacy/CSM mode"
        print_warning "4. Save and exit, then boot from Arch Linux USB again"
        exit 1
    fi
    
    # Check internet connection
    print_status "Checking internet connection..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        print_error "No internet connection. Please connect to the internet first."
        print_warning "Connection options:"
        print_warning "1. Wi-Fi: Use 'iwctl' command to connect"
        print_warning "2. Ethernet: Connect cable and run 'dhcpcd'"
        print_warning "3. USB Tethering: Use phone's mobile data"
        exit 1
    fi
    
    # Update system clock
    print_status "Synchronizing system clock..."
    if ! timedatectl set-ntp true; then
        print_warning "Failed to set NTP. Continuing with local time..."
    fi
    
    # Check available disk space
    print_status "Checking available disk space..."
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1048576 ]]; then  # Less than 1GB
        print_warning "Low disk space detected. Installation may fail."
        print_warning "Available space: $(($available_space / 1024))MB"
    fi
    
    print_status "Prerequisites check completed."
}

# Function to partition disk
partition_disk() {
    print_header "Partitioning Disk"
    
    if [[ $DUAL_BOOT == "y" ]]; then
        print_status "Dual-boot mode: Preserving existing partitions"
        print_warning "Please ensure you have already shrunk Windows partition!"
        
        # Show current partitions
        print_status "Current partition layout:"
        lsblk $DISK_DEVICE
        
        echo ""
        print_warning "This script assumes:"
        print_warning "- EFI partition exists (will be reused)"
        print_warning "- Free space available for Linux partitions"
        
        read -p "Continue with automatic partitioning of free space? (y/n): " continue_part
        if [[ $continue_part != "y" ]]; then
            print_error "Please partition manually and run script again."
            exit 1
        fi
        
        # Find the last partition number
        last_part=$(lsblk -rno NAME $DISK_DEVICE | tail -1 | grep -o '[0-9]*$')
        
        # Create partitions in free space
        print_status "Creating Linux partitions..."
        
        # Calculate swap size (equal to RAM)
        ram_size=$(free -m | awk '/^Mem:/{print $2}')
        swap_size=$((ram_size + 1000))  # Add 1GB buffer
        
        # Create partitions using sgdisk
        sgdisk -n 0:0:+${swap_size}M -t 0:8200 -c 0:"Linux Swap" $DISK_DEVICE
        sgdisk -n 0:0:0 -t 0:8300 -c 0:"Linux Root" $DISK_DEVICE
        
        # Update partition variables after creation
        swap_part="${DISK_DEVICE}p$((last_part + 1))"
        root_part="${DISK_DEVICE}p$((last_part + 2))"
        
        # Find EFI partition
        efi_part=$(lsblk -rno NAME,PARTTYPE $DISK_DEVICE | grep -i "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | cut -d' ' -f1)
        efi_part="/dev/$efi_part"
        
    else
        print_status "Single-boot mode: Creating new partition table"
        
        # Wipe disk and create new GPT
        sgdisk -Z $DISK_DEVICE
        sgdisk -o $DISK_DEVICE
        
        # Calculate partition sizes
        ram_size=$(free -m | awk '/^Mem:/{print $2}')
        swap_size=$((ram_size + 1000))
        
        # Create partitions
        sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" $DISK_DEVICE
        sgdisk -n 2:0:+${swap_size}M -t 2:8200 -c 2:"Linux Swap" $DISK_DEVICE
        sgdisk -n 3:0:0 -t 3:8300 -c 3:"Linux Root" $DISK_DEVICE
        
        efi_part="${DISK_DEVICE}p1"
        swap_part="${DISK_DEVICE}p2"
        root_part="${DISK_DEVICE}p3"
    fi
    
    # Inform kernel of partition changes
    partprobe $DISK_DEVICE
    sleep 2
    
    print_status "Partitioning completed."
    print_status "EFI: $efi_part"
    print_status "Swap: $swap_part"
    print_status "Root: $root_part"
}

# Function to format partitions
format_partitions() {
    print_header "Formatting Partitions"
    
    # Format EFI partition (only if single-boot)
    if [[ $DUAL_BOOT != "y" ]]; then
        print_status "Formatting EFI partition..."
        mkfs.fat -F32 -n "EFI" $efi_part
    fi
    
    # Format swap
    print_status "Setting up swap..."
    mkswap -L "Arch_Swap" $swap_part
    swapon $swap_part
    
    # Format root with ZFS
    print_status "Formatting root partition with ZFS..."
    # ZFS will be set up after base system installation
    
    print_status "Partition formatting completed."
}

# Function to setup ZFS
setup_zfs() {
    print_header "Setting up ZFS"
    
    # Check available disk space for ZFS
    print_status "Checking disk space for ZFS installation..."
    local available_space=$(df /mnt 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
    local required_space=2097152  # 2GB minimum for ZFS
    
    if [[ $available_space -lt $required_space ]]; then
        print_error "Insufficient disk space for ZFS installation."
        print_error "Available: $(($available_space / 1024))MB, Required: $(($required_space / 1024))MB"
        print_warning "Consider:"
        print_warning "1. Free up more space on the target disk"
        print_warning "2. Use a different file system (ext4)"
        print_warning "3. Shrink Windows partition further"
        exit 1
    fi
    
    print_status "Disk space check passed: $(($available_space / 1024))MB available"
    
    # Create ZFS pool
    print_status "Creating ZFS pool..."
    zpool create -f -o ashift=12 \
        -O compression=zstd \
        -O acltype=posixacl \
        -O xattr=sa \
        -O relatime=on \
        -O normalization=formD \
        -O mountpoint=none \
        -O canmount=off \
        -O dnodesize=auto \
        -O sync=disabled \
        -R /mnt \
        zroot $root_part
    
    # Create ZFS datasets
    print_status "Creating ZFS datasets..."
    zfs create -o mountpoint=none zroot/ROOT
    zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/default
    zfs create -o mountpoint=/home zroot/home
    zfs create -o mountpoint=/var -o canmount=off zroot/var
    zfs create zroot/var/log
    zfs create zroot/var/cache
    zfs create -o mountpoint=/tmp -o sync=disabled zroot/tmp
    
    if [[ $ENABLE_SNAPSHOTS == "y" ]]; then
        print_status "Enabling ZFS snapshots..."
        zfs set com.sun:auto-snapshot=true zroot/ROOT/default
        zfs set com.sun:auto-snapshot=true zroot/home
    fi
    
    # Mount ZFS datasets
    print_status "Mounting ZFS datasets..."
    zfs mount zroot/ROOT/default
    zfs mount -a
    
    # Create mount points and mount EFI
    mkdir -p /mnt/boot
    mount $efi_part /mnt/boot
    
    print_status "ZFS setup completed."
}

# Function to install base system
install_base_system() {
    print_header "Installing Base System"
    
    # Update package database
    print_status "Updating package database..."
    if ! pacman -Sy; then
        print_error "Failed to update package database. Check internet connection."
        exit 1
    fi
    
    # Install base system
    print_status "Installing base packages (this may take 5-10 minutes)..."
    if ! pacstrap /mnt base linux linux-firmware base-devel; then
        print_error "Failed to install base packages. Check disk space and internet connection."
        exit 1
    fi
    
    # Install essential packages
    print_status "Installing essential packages..."
    if ! pacstrap /mnt vim nano networkmanager git wget curl intel-ucode amd-ucode; then
        print_error "Failed to install essential packages."
        exit 1
    fi
    
    if ! pacstrap /mnt grub efibootmgr; then
        print_error "Failed to install bootloader packages."
        exit 1
    fi
    
    # Install hardware-specific packages
    print_status "Installing hardware-specific packages..."
    if ! pacstrap /mnt mesa xf86-video-amdgpu linux-headers; then
        print_error "Failed to install hardware packages."
        exit 1
    fi
    
    # Install ZFS support
    print_status "Installing ZFS packages (this may take 5-15 minutes)..."
    if ! pacstrap /mnt zfs-dkms zfs-utils; then
        print_error "Failed to install ZFS packages. Check internet connection and disk space."
        exit 1
    fi
    
    # Install dual-boot support if needed
    if [[ $DUAL_BOOT == "y" ]]; then
        print_status "Installing dual-boot support..."
        if ! pacstrap /mnt os-prober ntfs-3g; then
            print_warning "Failed to install dual-boot packages. Continuing..."
        fi
    fi
    
    # Install snapshot tools if enabled
    if [[ $ENABLE_SNAPSHOTS == "y" ]]; then
        print_status "Installing snapshot tools..."
        if ! pacstrap /mnt zfs-auto-snapshot; then
            print_warning "Failed to install snapshot tools. Continuing..."
        fi
    fi
    
    print_status "Base system installation completed."
}

# Function to configure system
configure_system() {
    print_header "Configuring System"
    
    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # Chroot and configure
    arch-chroot /mnt /bin/bash << EOF
# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Configure localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "$HOSTNAME" > /etc/hostname

# Configure hosts
cat >> /etc/hosts << EOH
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOH

# Configure GRUB
if [[ "$DUAL_BOOT" == "y" ]]; then
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
fi

# Add Z13-specific kernel parameters
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& i915.enable_psr=0 ibt=off/' /etc/default/grub

# Install and configure GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Create user
useradd -m -G wheel -s /bin/bash $USERNAME

# Enable sudo for wheel group
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable essential services
systemctl enable NetworkManager
systemctl enable fstrim.timer
systemctl enable systemd-timesyncd

EOF

    print_status "System configuration completed."
}

# Function to apply Z13-specific fixes
apply_z13_fixes() {
    print_header "Applying ASUS ROG Flow Z13 Hardware Fixes"
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Fix Wi-Fi stability (MediaTek MT7925e)
mkdir -p /etc/modprobe.d
echo "options mt7925e disable_aspm=1" > /etc/modprobe.d/mt7925e.conf

# Fix touchpad detection
cat > /etc/systemd/system/reload-hid_asus.service << EOH
[Unit]
Description=Reload hid_asus module for touchpad detection
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/modprobe -r hid_asus
ExecStart=/usr/bin/modprobe hid_asus

[Install]
WantedBy=multi-user.target
EOH

systemctl enable reload-hid_asus.service

EOF

    print_status "Z13-specific fixes applied."
}

# Function to install power management
install_power_management() {
    if [[ $INSTALL_POWER_MGMT == "y" ]]; then
        print_header "Installing Power Management"
        
        arch-chroot /mnt /bin/bash << EOF
# Install AUR helper first
pacman -S --noconfirm --needed git base-devel
cd /tmp
sudo -u $USERNAME git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u $USERNAME makepkg -si --noconfirm
cd /

# Install power management packages
pacman -S --noconfirm power-profiles-daemon tlp
sudo -u $USERNAME yay -S --noconfirm asusctl

# Enable services
systemctl enable power-profiles-daemon
systemctl enable tlp

# Configure TLP for maximum performance when plugged in
cat >> /etc/tlp.conf << EOH
# Z13 Power Management Configuration - AMD Ryzen Strix Halo (45W-120W+ TDP)
TLP_DEFAULT_MODE=AC
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=30
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# Strix Halo TDP Control (via asusctl)
# Performance: 120W+ TDP (gaming, rendering)
# Balanced: 70W TDP (general use)
# Power-saver: 45W TDP (battery life)
EOH

EOF

        print_status "Power management installed and configured."
    fi
}

# Function to install desktop environment
install_desktop() {
    print_header "Installing Desktop Environment: $INSTALL_DESKTOP"
    
    case $INSTALL_DESKTOP in
        "omarchy")
            arch-chroot /mnt /bin/bash << EOF
# Install Omarchy tiling window manager
pacman -S --noconfirm xorg-server xorg-xinit
pacman -S --noconfirm lightdm lightdm-gtk-greeter
pacman -S --noconfirm firefox alacritty thunar
pacman -S --noconfirm pulseaudio pulseaudio-alsa pavucontrol
pacman -S --noconfirm network-manager-applet

# Install Omarchy from AUR
pacman -S --noconfirm --needed git base-devel
cd /tmp
sudo -u $USERNAME git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u $USERNAME makepkg -si --noconfirm
cd /
sudo -u $USERNAME yay -S --noconfirm omarchy

# Enable display manager
systemctl enable lightdm
EOF
            ;;
        "xfce")
            arch-chroot /mnt /bin/bash << EOF
# Install XFCE desktop environment
pacman -S --noconfirm xfce4 xfce4-goodies xorg-server
pacman -S --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -S --noconfirm firefox thunar-archive-plugin file-roller
pacman -S --noconfirm pulseaudio pulseaudio-alsa pavucontrol
pacman -S --noconfirm network-manager-applet

# Enable display manager
systemctl enable lightdm
EOF
            ;;
        "i3")
            arch-chroot /mnt /bin/bash << 'EOF'
pacman -S --noconfirm xorg-server xorg-xinit i3-wm i3status i3lock dmenu
pacman -S --noconfirm lightdm lightdm-gtk-greeter
pacman -S --noconfirm firefox alacritty thunar
pacman -S --noconfirm pulseaudio pulseaudio-alsa pavucontrol
pacman -S --noconfirm network-manager-applet
systemctl enable lightdm
EOF
            ;;
        "gnome")
            arch-chroot /mnt /bin/bash << 'EOF'
pacman -S --noconfirm gnome gnome-extra
pacman -S --noconfirm firefox
systemctl enable gdm
EOF
            ;;
        "kde")
            arch-chroot /mnt /bin/bash << 'EOF'
pacman -S --noconfirm plasma kde-applications
pacman -S --noconfirm firefox
systemctl enable sddm
EOF
            ;;
        "minimal")
            print_status "Minimal installation - no desktop environment."
            ;;
    esac
    
    print_status "Desktop environment installation completed."
}

# Function to install gaming setup
install_gaming() {
    if [[ $INSTALL_GAMING == "y" ]]; then
        print_header "Installing Gaming Setup"
        
        arch-chroot /mnt /bin/bash << 'EOF'
# Enable multilib repository
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Sy

# Install gaming packages
pacman -S --noconfirm steam gamemode mangohud
pacman -S --noconfirm wine winetricks lutris

# Install additional gaming dependencies
pacman -S --noconfirm lib32-mesa lib32-vulkan-radeon vulkan-radeon

EOF

        print_status "Gaming setup completed."
    fi
}

# Function to configure snapshots
configure_snapshots() {
    if [[ $ENABLE_SNAPSHOTS == "y" ]]; then
        print_header "Configuring ZFS Snapshots"
        
        arch-chroot /mnt /bin/bash << 'EOF'
# Configure ZFS snapshots (already configured in setup_zfs function)
# ZFS snapshots are automatically managed by zfs-auto-snapshot

# Enable automatic snapshots
systemctl enable zfs-snapshot-boot.timer
systemctl enable zfs-snapshot-hourly.timer
systemctl enable zfs-snapshot-daily.timer
systemctl enable zfs-snapshot-weekly.timer
systemctl enable zfs-snapshot-monthly.timer

EOF

        print_status "Snapshot configuration completed."
    fi
}

# Function to set passwords
set_passwords() {
    print_header "Setting Passwords"
    
    echo "Set root password:"
    arch-chroot /mnt passwd
    
    echo "Set password for user $USERNAME:"
    arch-chroot /mnt passwd $USERNAME
}

# Function to final system update
final_update() {
    print_header "Final System Update"
    
    arch-chroot /mnt /bin/bash << 'EOF'
pacman -Syu --noconfirm
EOF

    print_status "System update completed."
}

# Function to cleanup on failure
cleanup_on_failure() {
    print_error "Installation failed. Cleaning up..."
    
    if [[ $ZFS_POOL_CREATED == true ]]; then
        print_status "Destroying ZFS pool..."
        zpool destroy -f zroot 2>/dev/null || true
    fi
    
    if [[ -d /mnt ]]; then
        print_status "Unmounting filesystems..."
        umount -R /mnt 2>/dev/null || true
    fi
    
    print_error "Cleanup completed. You can try the installation again."
    exit 1
}

# Function to cleanup and finish
cleanup_and_finish() {
    print_header "Installation Complete"
    
    # Unmount all partitions
    umount -R /mnt
    
    print_status "Installation completed successfully!"
    print_status ""
    print_status "System optimized for:"
    print_status "• Maximum performance when plugged in"
    print_status "• Advanced power management (7W-120W+ TDP control)"
    print_status "• Hassle-free laptop and tablet use"
    print_status ""
    print_status "Next steps:"
    print_status "1. Remove installation media"
    print_status "2. Reboot into your new Arch Linux system"
    print_status "3. Test dual-boot functionality (if enabled)"
    print_status "4. Configure power profiles using: powerprofilesctl set [performance|balanced|power-saver]"
    print_status ""
    
    read -p "Reboot now? (y/n): " reboot_now
    if [[ $reboot_now == "y" ]]; then
        reboot
    fi
}

# Main installation function
main() {
    print_header "ASUS ROG Flow Z13 Arch Linux Installation Script"
    print_status "Version 1.0.0 - September 10, 2025"
    print_status ""
    
    # Set up error handling
    trap cleanup_on_failure ERR
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (from Arch Linux installation media)"
        exit 1
    fi
    
    INSTALLATION_STARTED=true
    
    # Run installation steps
    configure_installation
    check_prerequisites
    partition_disk
    format_partitions
    setup_zfs
    ZFS_POOL_CREATED=true
    install_base_system
    BASE_SYSTEM_INSTALLED=true
    configure_system
    apply_z13_fixes
    install_power_management
    install_desktop
    install_gaming
    configure_snapshots
    set_passwords
    final_update
    cleanup_and_finish
}

# Run main function
main "$@"
