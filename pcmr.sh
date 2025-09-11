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
MODULES_DIR="$(dirname "$0")/Modules"
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

# Standardized error handling functions
HandleFatalError() {
    local error_msg="$1"
    PrintError "$error_msg"
    # Log to system log if available
    logger -t "pcmr-installer" "FATAL: $error_msg" 2>/dev/null || true
    exit 1
}

HandleRecoverableError() {
    local error_msg="$1"
    PrintError "$error_msg"
    # Log to system log if available  
    logger -t "pcmr-installer" "RECOVERABLE: $error_msg" 2>/dev/null || true
    return 1
}

HandleValidationError() {
    local error_msg="$1"
    PrintError "$error_msg"
    # Log to system log if available
    logger -t "pcmr-installer" "VALIDATION: $error_msg" 2>/dev/null || true
    exit 1
}

# Print functions (TUI-aware)
PrintHeader() {
    local message="$1"
    if [[ "$TUI_ENABLED" == true ]]; then
        add_log_message "$message"
    else
        echo -e "${BLUE}================================${NC}"
        echo -e "${BLUE}$message${NC}"
        echo -e "${BLUE}================================${NC}"
    fi
}

PrintStatus() {
    local message="$1"
    if [[ "$TUI_ENABLED" == true ]]; then
        add_log_message "$message"
    else
        echo -e "${GREEN}[INFO]${NC} $message"
    fi
}

PrintWarning() {
    local message="$1"
    if [[ "$TUI_ENABLED" == true ]]; then
        tui_warning "$message"
    else
        echo -e "${YELLOW}[WARN]${NC} $message"
    fi
}

PrintError() {
    local message="$1"
    if [[ "$TUI_ENABLED" == true ]]; then
        tui_error "$message"
    else
        echo -e "${RED}[ERROR]${NC} $message"
    fi
}

# Function to show help
ShowHelp() {
    cat << EOF
PCMR Arch Linux Installation Script
ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --config FILE          Load configuration from specified file (default: Configs/pcmr-standard.conf)
    --standard             Ignore config file and use standard installation
    --dual-boot-gpt        Modern GPT UEFI dual boot mode (existing Windows)
    --dual-boot-new        Fresh install EFI for new Windows + Arch dual boot
    --zen-kernel           Use zen kernel instead of standard kernel
    --help, -h             Show this help message

EXAMPLES:
    $0 --config Configs/pcmr-standard.conf
    $0 --standard
    $0 --dual-boot-gpt --zen-kernel
    $0 --dual-boot-new

CONFIGURATION:
    The script can load configuration from a file (default: Configs/pcmr-standard.conf)
    Available configurations:
    - Configs/PcmrStandard.conf: Standard Z13 Flow configuration
    - Configs/Level1Techs.conf: Level1Techs-inspired configuration

DUAL BOOT MODES:
    --dual-boot-gpt        For existing Windows UEFI installations
    --dual-boot-new        For fresh dual boot installations

FILESYSTEMS:
    ZFS (default)          Advanced features, snapshots, compression
    Btrfs (fallback)       Modern features, snapshots
    ext4 (fallback)        Stable, compatible

FEATURES:
    - AMD Strix Halo AI Max+ optimization
               - Configurable TDP (7W-120W with dynamic power management)
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
LoadConfig() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        HandleFatalError "Configuration file not found: $config_file"
    fi
    
    PrintStatus "Loading configuration from: $config_file"
    
    # Source the configuration file
    source "$config_file"
    
    PrintStatus "Configuration loaded successfully"
}

# Function to detect dual boot mode automatically
DetectDualBoot() {
    PrintStatus "Detecting existing dual boot configuration..."
    
    # Check if we're in UEFI mode (required for Z13 Flow 2025)
    if [[ -d /sys/firmware/efi ]]; then
        PrintStatus "System is in UEFI mode"
        
        # Look for Windows EFI partition
        local efi_part=$(lsblk -rno NAME,PARTTYPE | grep -i "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | cut -d' ' -f1)
        
        if [[ -n "$efi_part" ]]; then
            PrintStatus "Found existing EFI partition: $efi_part"
            
            # Check EFI partition size
            local efi_size=$(lsblk -b "/dev/$efi_part" | awk 'NR==2 {print $4}' | awk '{print int($1/1024/1024)}')
            if [[ $efi_size -lt 100 ]]; then
                HandleFatalError "EFI partition is only ${efi_size}MB. This is too small for dual boot. Please resize EFI partition to at least 100MB before continuing. See: https://wiki.archlinux.org/title/Dual_boot_with_Windows#The_EFI_system_partition_created_by_Windows_Setup_is_too_small"
            fi
            
            # Check if Windows is installed
            local windows_part=$(lsblk -rno NAME,FSTYPE | grep -i "ntfs" | head -1 | cut -d' ' -f1)
            
            if [[ -n "$windows_part" ]]; then
                PrintStatus "Found Windows installation, using --dual-boot-gpt mode"
                DUAL_BOOT_MODE="gpt"
            else
                PrintStatus "No Windows found, using --dual-boot-new mode"
                DUAL_BOOT_MODE="new"
            fi
        else
            PrintStatus "No EFI partition found, using --dual-boot-new mode"
            DUAL_BOOT_MODE="new"
        fi
    else
        HandleFatalError "System is not in UEFI mode. Z13 Flow 2025 requires UEFI mode. Please boot in UEFI mode and try again."
    fi
}

# Function to load modules
LoadModule() {
    local module_name="$1"
    local module_file="$MODULES_DIR/${module_name}.sh"
    
    if [[ -f "$module_file" ]]; then
        PrintStatus "Loading module: $module_name"
        source "$module_file"
    else
        HandleFatalError "Module not found: $module_file"
    fi
}

# Function to show installation summary
ShowSummary() {
    PrintHeader "Installation Summary"
    
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
        PrintWarning "Dual boot installation will preserve existing Windows installation"
        PrintWarning "Make sure you have backed up important data"
    fi
    
    echo "Press Enter to continue or Ctrl+C to cancel..."
    read -r
}

# Function to validate prerequisites
ValidatePrerequisites() {
    PrintHeader "Validating Prerequisites"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        HandleFatalError "This script must be run as root"
    fi
    
    # Check if we're in a chroot environment
    if [[ -f /.arch-chroot ]]; then
        HandleFatalError "This script should not be run inside a chroot environment"
    fi
    
    # Check if zsh is available (should be in Arch live environment)
    if ! command -v zsh >/dev/null 2>&1; then
        PrintWarning "Zsh not found in live environment. Installing during setup..."
        ZSH_NEEDS_INSTALL=true
    else
        PrintStatus "Zsh available in live environment"
        ZSH_NEEDS_INSTALL=false
    fi
    
    # Check internet connection
    if ! ping -c 1 archlinux.org &> /dev/null; then
        HandleFatalError "No internet connection. Please connect to the internet and try again."
    fi
    
    PrintStatus "Prerequisites validated successfully"
}

# Function to cleanup on failure
CleanupOnFailure() {
    if [[ "$INSTALLATION_STARTED" == true ]]; then
        PrintError "Installation failed. Cleaning up..."
        
        # Unmount filesystems
        umount -R /mnt 2>/dev/null || true
        
        # Destroy ZFS pool if created
        if [[ "$FILESYSTEM_CREATED" == "zfs" ]]; then
            zpool destroy -f zroot 2>/dev/null || true
        fi
        
        PrintError "Cleanup completed"
    fi
}

# Function to cleanup and finish
CleanupAndFinish() {
    PrintHeader "Finalizing Installation"
    
    # Unmount filesystems
    umount -R /mnt
    
    PrintStatus "Installation completed successfully!"
    PrintStatus "You can now reboot into your new Arch Linux installation"
    PrintStatus "Remember to remove the installation media before rebooting"
}

# Main function
Main() {
    # Set up error handling
    trap CleanupOnFailure EXIT
    
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
                ShowHelp
                exit 0
                ;;
            *)
                PrintError "Unknown option: $1"
                ShowHelp
                HandleFatalError "Invalid command line option"
                ;;
        esac
    done
    
    # Load configuration if requested
    if [[ "$use_config" == true ]]; then
        if [[ -z "$config_file" ]]; then
            config_file="Configs/Zen.conf"
        fi
        LoadConfig "$config_file"
    else
        PrintStatus "Using standard installation mode (ignoring config file)"
    fi
    
    # Auto-detect dual boot if not specified
    if [[ -z "$DUAL_BOOT_MODE" ]]; then
        DetectDualBoot
    fi
    
    # Validate dual boot mode
    case "$DUAL_BOOT_MODE" in
        "gpt"|"new"|"none")
            # Valid modes
            ;;
        *)
            HandleValidationError "Invalid dual boot mode: $DUAL_BOOT_MODE. Valid modes: gpt, new, none"
            ;;
    esac
    
    # Validate prerequisites
    ValidatePrerequisites
    
    # Show installation summary
    ShowSummary
    
    INSTALLATION_STARTED=true
    
    # Load TUI display system
    if [[ -f "$(dirname "$0")/Modules/TuiDisplay.sh" ]]; then
        source "$(dirname "$0")/Modules/TuiDisplay.sh"
        TUI_ENABLED=true
        InitTui
        
        # Set TUI mode based on how script was called
        if [[ "$use_config" == true ]]; then
            local config_basename=$(basename "$config_file" .conf)
            TuiSetMode "CONFIG" "$config_basename"
        elif [[ "$#" -eq 0 ]]; then
            TuiSetMode "AUTO" ""
        else
            TuiSetMode "MANUAL" ""
        fi
    else
        TUI_ENABLED=false
        PrintWarning "TUI display not available, using standard output"
    fi
    
    # Load and execute core installation system
    LoadModule "CoreInstallation"
    
    # Run core installation (which orchestrates all modules)
    if [[ "$TUI_ENABLED" == true ]]; then
        AddLogMessage "Starting PCMR Arch Linux Installation"
        AddLogMessage "Configuration: ${DUAL_BOOT_MODE:-Auto} | $([ "$USE_ZEN_KERNEL" == true ] && echo "Zen" || echo "Standard") kernel"
        AddLogMessage "Filesystem: $FILESYSTEM | Desktop: $DESKTOP_ENVIRONMENT"
    fi
    
    CoreInstallation
    BASE_SYSTEM_INSTALLED=true
    
    if [[ "$TUI_ENABLED" == true ]]; then
        AddLogMessage "🎉 Installation completed successfully!"
        AddLogMessage "System ready for first boot"
        CleanupTui
    fi
    
    CleanupAndFinish
}

# Run main function with all arguments
Main "$@"
