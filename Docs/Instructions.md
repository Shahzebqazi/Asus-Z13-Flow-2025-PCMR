# Arch Linux Installation Instructions for ASUS ROG Flow Z13

## Prerequisites

- **Backup Data:** Ensure all important data is backed up before proceeding
- **Create Bootable USB:** Download the latest Arch Linux ISO and create a bootable USB using tools like `dd`, `Rufus`, or `Ventoy`
- **BIOS Settings:** Access BIOS/UEFI settings (F2 during boot) and disable Secure Boot temporarily

## Phase 1: Base Installation

### 1. Boot from USB
```bash
# Insert bootable USB and boot from it
# At GRUB menu, select "Arch Linux install medium"
```
**Comment:** The Z13 should boot directly from USB. If not, check BIOS boot order settings.

### 2. Handle Nouveau Driver Issues
```bash
# At boot menu, press 'e' to edit boot parameters
# Append to linux line: modprobe.blacklist=nouveau
# Press Ctrl+X to boot
```
**Comment:** The Z13's hybrid graphics can cause conflicts with nouveau driver during installation. This prevents system hangs.

### 3. Connect to Internet
```bash
# For Wi-Fi (MediaTek MT7925e has known issues)
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "YOUR_SSID"
exit

# Test connection
ping archlinux.org
```
**Comment:** The MediaTek Wi-Fi chip may be unstable. If connection fails, use USB tethering from phone or ethernet adapter.

### 4. Update System Clock
```bash
timedatectl set-ntp true
timedatectl status
```
**Comment:** Ensures accurate timestamps for package installation and system logs.

### 5. Partition the Disk
```bash
# List available disks
lsblk

# Use cgdisk for partitioning (assuming /dev/nvme0n1)
cgdisk /dev/nvme0n1

# Create partitions:
# 1. EFI System Partition: 512MB, type EF00
# 2. Root partition: Remaining space minus swap, type 8300  
# 3. Swap partition: 16GB (or equal to RAM), type 8200
```
**Comment:** The Z13 uses NVMe storage. EFI partition is required for UEFI boot. Swap size should match RAM for hibernation support.

### 6. Format Partitions
```bash
# Format EFI partition
mkfs.fat -F32 /dev/nvme0n1p1

# Format root partition with Btrfs
mkfs.btrfs /dev/nvme0n1p2

# Setup swap
mkswap /dev/nvme0n1p3
swapon /dev/nvme0n1p3
```
**Comment:** Btrfs provides snapshots, compression, and subvolumes for better system management and recovery.

### 7. Create Btrfs Subvolumes
```bash
# Mount root partition temporarily
mount /dev/nvme0n1p2 /mnt

# Create subvolumes for better organization and snapshots
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots

# Unmount to remount with subvolumes
umount /mnt
```
**Comment:** Subvolumes allow independent snapshots of system components and easier rollback if updates break the system.

### 8. Mount Filesystems
```bash
# Mount root subvolume with optimizations for SSD
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@ /dev/nvme0n1p2 /mnt

# Create mount points
mkdir -p /mnt/{boot,home,var,tmp,.snapshots}

# Mount other subvolumes
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@home /dev/nvme0n1p2 /mnt/home
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@var /dev/nvme0n1p2 /mnt/var
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@tmp /dev/nvme0n1p2 /mnt/tmp
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@.snapshots /dev/nvme0n1p2 /mnt/.snapshots

# Mount EFI partition
mount /dev/nvme0n1p1 /mnt/boot
```
**Comment:** Mount options optimize for SSD performance and enable compression to save space. noatime reduces write operations.

### 9. Install Base System
```bash
# Install base system with essential packages
pacstrap /mnt base linux linux-firmware base-devel

# Install additional essential packages
pacstrap /mnt vim nano networkmanager git wget curl
```
**Comment:** base-devel is needed for AUR packages. NetworkManager will handle Wi-Fi after reboot.

### 10. Generate Fstab
```bash
# Generate filesystem table
genfstab -U /mnt >> /mnt/etc/fstab

# Verify fstab entries
cat /mnt/etc/fstab
```
**Comment:** Using UUIDs (-U flag) makes the system more resilient to drive letter changes.

### 11. Chroot into New System
```bash
arch-chroot /mnt
```
**Comment:** This changes root to the new installation, allowing system configuration.

### 12. Configure System
```bash
# Set timezone (adjust for your location)
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# Configure localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "z13-arch" > /etc/hostname

# Configure hosts file
cat >> /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   z13-arch.localdomain z13-arch
EOF
```
**Comment:** Replace timezone and hostname as needed. The hostname should be unique on your network.

### 13. Set Root Password
```bash
passwd
```
**Comment:** Choose a strong password for the root account.

### 14. Install and Configure Bootloader
```bash
# Install GRUB and EFI boot manager
pacman -S grub efibootmgr

# Install GRUB to EFI partition
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Generate GRUB configuration
grub-mkconfig -o /boot/grub/grub.cfg
```
**Comment:** GRUB handles the boot process. The bootloader-id can be customized.

### 15. Enable Essential Services
```bash
# Enable NetworkManager for Wi-Fi management
systemctl enable NetworkManager

# Enable fstrim for SSD maintenance
systemctl enable fstrim.timer
```
**Comment:** NetworkManager will handle network connections. fstrim maintains SSD performance.

### 16. Create User Account
```bash
# Create user account (replace 'username' with desired name)
useradd -m -G wheel -s /bin/bash username
passwd username

# Enable sudo for wheel group
EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL
```
**Comment:** Replace 'username' with your preferred username. wheel group provides sudo access.

### 17. Exit and Reboot
```bash
# Exit chroot
exit

# Unmount all partitions
umount -R /mnt

# Reboot into new system
reboot
```
**Comment:** Remove the USB drive after reboot to boot into the new Arch installation.

## Phase 1 Hardware-Specific Fixes

### Fix Wi-Fi Stability (MediaTek MT7925e)
```bash
# Create modprobe configuration to disable ASPM
sudo mkdir -p /etc/modprobe.d
echo "options mt7925e disable_aspm=1" | sudo tee /etc/modprobe.d/mt7925e.conf

# Reload the module
sudo modprobe -r mt7925e
sudo modprobe mt7925e
```
**Comment:** The MediaTek Wi-Fi chip has ASPM (Active State Power Management) issues causing disconnections.

### Fix Touchpad Detection
```bash
# Create systemd service to reload hid_asus module
sudo tee /etc/systemd/system/reload-hid_asus.service << EOF
[Unit]
Description=Reload hid_asus module for touchpad detection
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/modprobe -r hid_asus
ExecStart=/usr/bin/modprobe hid_asus

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl enable reload-hid_asus.service
```
**Comment:** The Z13 touchpad sometimes isn't detected on boot. This service forces module reload.

### Fix Screen Flickering
```bash
# Edit GRUB configuration to disable Intel PSR
sudo nano /etc/default/grub

# Modify GRUB_CMDLINE_LINUX line to include:
GRUB_CMDLINE_LINUX="i915.enable_psr=0 ibt=off"

# Update GRUB configuration
sudo grub-mkconfig -o /boot/grub/grub.cfg
```
**Comment:** Intel Panel Self Refresh causes flickering on the Z13's display. Disabling it fixes the issue.

## Post-Installation Verification

### 1. Check System Status
```bash
# Verify boot process
systemctl status

# Check disk usage
df -h

# Verify network connectivity
ping archlinux.org

# Check hardware detection
lspci
lsusb
```

### 2. Update System
```bash
# Update package database and system
sudo pacman -Syu
```

### 3. Install AUR Helper (Optional)
```bash
# Install yay AUR helper
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay
```
**Comment:** AUR helper makes it easier to install packages from Arch User Repository.

## Next Steps
After completing Phase 1, the system should boot successfully with basic functionality. The next phase will cover:
- Desktop environment installation
- Gaming setup with Steam and Proton
- Advanced power management configuration
- Performance optimizations

## Troubleshooting Common Issues

### Boot Issues
- If system doesn't boot, check GRUB installation and EFI partition
- Verify BIOS settings (Secure Boot disabled, UEFI mode)

### Wi-Fi Issues  
- Try different Wi-Fi networks
- Check if USB tethering works as alternative
- Consider USB Wi-Fi adapter as backup

### Display Issues
- If screen flickers, ensure PSR is disabled in GRUB
- Try different display managers if using GUI

### Performance Issues
- Check if all SSD optimizations are applied
- Verify Btrfs mount options are correct
- Monitor system resources with `htop`
