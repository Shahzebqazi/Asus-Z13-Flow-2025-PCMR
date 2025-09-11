#!/bin/bash
# PCMR Arch Linux Installation Script
# ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+
# Author: sqazi
# Version: 2.0.0
# Date: September 11, 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
MODULES_DIR="$(dirname "$0")/modules"
INSTALLATION_STARTED=false
BASE_SYSTEM_INSTALLED=false

# Default configuration
DUAL_BOOT_MODE=""
USE_ZEN_KERNEL=false
FILESYSTEM="zfs"
DESKTOP_ENVIRONMENT="xfce"
INSTALL_GAMING=false
INSTALL_POWER_MGMT=true
ENABLE_HARDWARE_FIXES=true
ENABLE_ERROR_RECOVERY=true
ENABLE_FILESYSTEM_FALLBACK=true
ENABLE_SNAPSHOTS=true

# Disk and partition variables
DISK_DEVICE=""
EFI_PART=""
ROOT_PART=""
SWAP_PART=""
WINDOWS_EXISTS=false
FILESYSTEM_CREATED=""
CURRENT_FILESYSTEM=""

# User configuration
USERNAME=""
HOSTNAME=""
TIMEZONE=""

# Print functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show help
show_help() {
    cat << EOF
PCMR Arch Linux Installation Script
ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --config FILE          Load configuration from specified file (default: configs/pcmr-standard.conf)
    --standard             Ignore config file and use standard installation
    --dual-boot-gpt        Modern GPT UEFI dual boot mode (existing Windows)
    --dual-boot-new        Fresh install EFI for new Windows + Arch dual boot
    --zen-kernel           Use zen kernel instead of standard kernel
    --help, -h             Show this help message

EXAMPLES:
    $0 --config configs/pcmr-standard.conf
    $0 --standard
    $0 --dual-boot-gpt --zen-kernel
    $0 --dual-boot-new

CONFIGURATION:
    The script can load configuration from a file (default: configs/pcmr-standard.conf)
    Available configurations:
    - configs/pcmr-standard.conf: Standard Z13 Flow configuration
    - configs/level1techs.conf: Level1Techs-inspired configuration

DUAL BOOT MODES:
    --dual-boot-gpt        For existing Windows UEFI installations
    --dual-boot-new        For fresh dual boot installations

FILESYSTEMS:
    ZFS (default)          Advanced features, snapshots, compression
    Btrfs (fallback)       Modern features, snapshots
    ext4 (fallback)        Stable, compatible

FEATURES:
    - AMD Strix Halo AI Max+ optimization
               - Configurable TDP (7W-54W)
    - Optimized fan curves
    - Steam and gaming support
    - Controller support (PS4/5, Xbox One/S)
    - Unified memory management
    - Power profiles (Efficient, AI, Gaming)
    - Hardware-specific fixes
    - Comprehensive error handling

For more information, see README.md
EOF
}

# Function to load configuration from file
load_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    print_status "Loading configuration from: $config_file"
    
    # Source the configuration file
    source "$config_file"
    
    print_status "Configuration loaded successfully"
}

# Function to detect dual boot mode automatically
detect_dual_boot() {
    print_status "Detecting existing dual boot configuration..."
    
    # Check if we're in UEFI mode (required for Z13 Flow 2025)
    if [[ -d /sys/firmware/efi ]]; then
        print_status "System is in UEFI mode"
        
        # Look for Windows EFI partition
        local efi_part=$(lsblk -rno NAME,PARTTYPE | grep -i "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | cut -d' ' -f1)
        
        if [[ -n "$efi_part" ]]; then
            print_status "Found existing EFI partition: $efi_part"
            
            # Check EFI partition size
            local efi_size=$(lsblk -b "/dev/$efi_part" | awk 'NR==2 {print $4}' | awk '{print int($1/1024/1024)}')
            if [[ $efi_size -lt 100 ]]; then
                print_error "EFI partition is only ${efi_size}MB. This is too small for dual boot."
                print_error "Please resize EFI partition to at least 100MB before continuing."
                print_error "See: https://wiki.archlinux.org/title/Dual_boot_with_Windows#The_EFI_system_partition_created_by_Windows_Setup_is_too_small"
                exit 1
            fi
            
            # Check if Windows is installed
            local windows_part=$(lsblk -rno NAME,FSTYPE | grep -i "ntfs" | head -1 | cut -d' ' -f1)
            
            if [[ -n "$windows_part" ]]; then
                print_status "Found Windows installation, using --dual-boot-gpt mode"
                DUAL_BOOT_MODE="gpt"
            else
                print_status "No Windows found, using --dual-boot-new mode"
                DUAL_BOOT_MODE="new"
            fi
        else
            print_status "No EFI partition found, using --dual-boot-new mode"
            DUAL_BOOT_MODE="new"
        fi
    else
        print_error "System is not in UEFI mode. Z13 Flow 2025 requires UEFI mode."
        print_error "Please boot in UEFI mode and try again."
        exit 1
    fi
}

# Function to load modules
load_module() {
    local module_name="$1"
    local module_file="$MODULES_DIR/${module_name}.sh"
    
    if [[ -f "$module_file" ]]; then
        print_status "Loading module: $module_name"
        source "$module_file"
    else
        print_error "Module not found: $module_file"
        exit 1
    fi
}

# Function to show installation summary
show_summary() {
    print_header "Installation Summary"
    
    echo "Configuration:"
    echo "  Dual Boot Mode: ${DUAL_BOOT_MODE:-"Auto-detect"}"
    echo "  Kernel: $([ "$USE_ZEN_KERNEL" == true ] && echo "Zen" || echo "Standard")"
    echo "  Filesystem: $FILESYSTEM"
    echo "  Desktop: $DESKTOP_ENVIRONMENT"
    echo "  Gaming: $([ "$INSTALL_GAMING" == true ] && echo "Yes" || echo "No")"
    echo "  Power Management: $([ "$INSTALL_POWER_MGMT" == true ] && echo "Yes" || echo "No")"
    echo "  Hardware Fixes: $([ "$ENABLE_HARDWARE_FIXES" == true ] && echo "Yes" || echo "No")"
    echo ""
    
    if [[ "$DUAL_BOOT_MODE" != "none" ]]; then
        print_warning "Dual boot installation will preserve existing Windows installation"
        print_warning "Make sure you have backed up important data"
    fi
    
    echo "Press Enter to continue or Ctrl+C to cancel..."
    read -r
}

# Function to validate prerequisites
validate_prerequisites() {
    print_header "Validating Prerequisites"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Check if we're in a chroot environment
    if [[ -f /.arch-chroot ]]; then
        print_error "This script should not be run inside a chroot environment"
        exit 1
    fi
    
    # Check internet connection
    if ! ping -c 1 archlinux.org &> /dev/null; then
        print_error "No internet connection. Please connect to the internet and try again."
        exit 1
    fi
    
    print_status "Prerequisites validated successfully"
}

# Function to cleanup on failure
cleanup_on_failure() {
    if [[ "$INSTALLATION_STARTED" == true ]]; then
        print_error "Installation failed. Cleaning up..."
        
        # Unmount filesystems
        umount -R /mnt 2>/dev/null || true
        
        # Destroy ZFS pool if created
        if [[ "$FILESYSTEM_CREATED" == "zfs" ]]; then
            zpool destroy -f zroot 2>/dev/null || true
        fi
        
        print_error "Cleanup completed"
    fi
}

# Function to cleanup and finish
cleanup_and_finish() {
    print_header "Finalizing Installation"
    
    # Unmount filesystems
    umount -R /mnt
    
    print_status "Installation completed successfully!"
    print_status "You can now reboot into your new Arch Linux installation"
    print_status "Remember to remove the installation media before rebooting"
}

# Main function
main() {
    # Set up error handling
    trap cleanup_on_failure EXIT
    
    # Parse command line arguments
    local use_config=false
    local config_file=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config)
                use_config=true
                config_file="$2"
                shift 2
                ;;
            --standard)
                use_config=false
                shift
                ;;
            --dual-boot-gpt)
                DUAL_BOOT_MODE="gpt"
                shift
                ;;
            --dual-boot-new)
                DUAL_BOOT_MODE="new"
                shift
                ;;
            --zen-kernel)
                USE_ZEN_KERNEL=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Load configuration if requested
    if [[ "$use_config" == true ]]; then
        local config_file="${1:-configs/pcmr-standard.conf}"
        load_config "$config_file"
    else
        print_status "Using standard installation mode (ignoring config file)"
    fi
    
    # Auto-detect dual boot if not specified
    if [[ -z "$DUAL_BOOT_MODE" ]]; then
        detect_dual_boot
    fi
    
    # Validate dual boot mode
    case "$DUAL_BOOT_MODE" in
        "gpt"|"new"|"none")
            # Valid modes
            ;;
        *)
            print_error "Invalid dual boot mode: $DUAL_BOOT_MODE"
            print_error "Valid modes: gpt, new, none"
            exit 1
            ;;
    esac
    
    # Validate prerequisites
    validate_prerequisites
    
    # Show installation summary
    show_summary
    
    INSTALLATION_STARTED=true
    
    # Load required modules
    load_module "disk_management"
    load_module "filesystem_setup"
    load_module "base_installation"
    load_module "system_configuration"
    load_module "Drivers_and_Hardware_Specific_Setup"
    load_module "TDP_Configuration"
    load_module "Steam_and_Gaming"
    load_module "hardware_setup"
    load_module "desktop_installation"
    
    # Run installation steps
    disk_management_setup
    filesystem_setup
    base_installation
    BASE_SYSTEM_INSTALLED=true
    system_configuration
    drivers_and_hardware_setup
    tdp_configuration_setup
    steam_gaming_setup
    hardware_setup
    desktop_installation
    cleanup_and_finish
}

# Run main function with all arguments
main "$@"
