#!/bin/bash
# PCMR Arch Linux Installation Script
# ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+
# Author: sqazi
# Version: 2.0.0
# Date: September 11, 2025

set -e
set -E

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
STATE_HOST_FILE="/tmp/pcmr-installer.state"
STATE_DIR="/mnt/var/lib/pcmr-installer"
STATE_FILE="$STATE_DIR/state"

# Default configuration
DUAL_BOOT_MODE=""
USE_ZEN_KERNEL=false
FILESYSTEM="ext4"
DESKTOP_ENVIRONMENT="omarchy"
INSTALL_GAMING=false
INSTALL_POWER_MGMT=true
ENABLE_HARDWARE_FIXES=true
ENABLE_ERROR_RECOVERY=true
ENABLE_FILESYSTEM_FALLBACK=true
ENABLE_SNAPSHOTS=false
ENABLE_SECURE_BOOT=false

# CLI flags
FORCE_NO_TUI=false

# Disk and partition variables
DISK_DEVICE=""
EFI_PART=""
ROOT_PART=""
SWAP_PART=""
WINDOWS_EXISTS=false
FILESYSTEM_CREATED=""
CURRENT_FILESYSTEM=""

# Configuration variables with defaults
USERNAME=""
HOSTNAME=""
TIMEZONE=""
ROOT_PASSWORD=""
USER_PASSWORD=""

# Default configuration values (loaded from default JSON config)
DEFAULT_USERNAME="archuser"
DEFAULT_HOSTNAME="arch-z13"
DEFAULT_TIMEZONE="UTC"
DEFAULT_LOCALE="en_US.UTF-8"
MIN_MEMORY_GB=2
MIN_ROOT_PARTITION_GB=20
SWAP_MIN_GB=8
SWAP_MAX_GB=32
TDP_EFFICIENT=7
TDP_AI=45
TDP_GAMING=93
TDP_MAXIMUM=120
BATTERY_START_THRESHOLD=40
BATTERY_STOP_THRESHOLD=80
TDP_MANAGER_PATH="/usr/local/bin/tdp-manager"
CONFIG_DIR="/etc/z13"
LOG_FILE="/var/log/z13-tdp.log"
ENABLE_FRESH_REINSTALL=true
ENABLE_DETACHED_MODE=true
MAX_RETRY_ATTEMPTS=3
CLEANUP_TIMEOUT=30
ENABLE_SECURITY_HARDENING=false
ENABLE_PERFORMANCE_OPTIMIZATION=false
ENABLE_SYSTEM_MONITORING=false
ENABLE_BACKUP_RECOVERY=false

# Installation state tracking
INSTALLATION_PHASE=""
RETRY_COUNT=0
DETACHED_MODE=false
DETACHED_PID=""

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

# Simple resume state helpers
ensure_state_dir() {
    if mountpoint -q /mnt; then
        mkdir -p "$STATE_DIR" || true
        touch "$STATE_FILE" || true
    fi
    touch "$STATE_HOST_FILE" || true
}

mark_phase_done() {
    local phase="$1"
    ensure_state_dir
    if [[ -n "$phase" ]]; then
        grep -qx "$phase" "$STATE_HOST_FILE" 2>/dev/null || echo "$phase" >> "$STATE_HOST_FILE"
        if [[ -f "$STATE_FILE" ]]; then
            grep -qx "$phase" "$STATE_FILE" 2>/dev/null || echo "$phase" >> "$STATE_FILE"
        fi
    fi
}

is_phase_done() {
    local phase="$1"
    [[ -f "$STATE_HOST_FILE" && $(grep -x "$phase" "$STATE_HOST_FILE" 2>/dev/null | wc -l) -gt 0 ]] && return 0
    [[ -f "$STATE_FILE" && $(grep -x "$phase" "$STATE_FILE" 2>/dev/null | wc -l) -gt 0 ]] && return 0
    return 1
}

run_phase() {
    local phase_name="$1"; shift
    local func_name="$1"; shift
    if is_phase_done "$phase_name"; then
        PrintStatus "Skipping phase '$phase_name' (already completed)"
        return 0
    fi
    PrintHeader "Running phase: $phase_name"
    "$func_name" "$@"
    mark_phase_done "$phase_name"
}

# Input validation functions
ValidateNumericInput() {
    local input="$1"
    local min="$2"
    local max="$3"
    local description="$4"
    
    # Check if input is numeric
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        HandleValidationError "Invalid $description: '$input' is not a number"
        return 1
    fi
    
    # Check range
    if [[ $input -lt $min || $input -gt $max ]]; then
        HandleValidationError "Invalid $description: '$input' must be between $min and $max"
        return 1
    fi
    
    return 0
}

ValidateChoice() {
    local choice="$1"
    local max_choice="$2"
    local description="$3"
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 || $choice -gt $max_choice ]]; then
        HandleValidationError "Invalid $description: Please enter a number between 1 and $max_choice"
        return 1
    fi
    
    return 0
}

ValidateYesNo() {
    local input="$1"
    local description="$2"
    
    if ! [[ "$input" =~ ^[YyNn]$ ]]; then
        HandleValidationError "Invalid $description: Please enter 'y' for yes or 'n' for no"
        return 1
    fi
    
    return 0
}

ValidateTimezone() {
    local timezone="$1"
    
    # Check if timezone exists
    if [[ ! -f "/usr/share/zoneinfo/$timezone" ]]; then
        HandleValidationError "Invalid timezone: '$timezone' does not exist"
        return 1
    fi
    
    return 0
}

ValidatePartition() {
    local partition="$1"
    local description="$2"
    
    # Check if partition exists as block device
    if [[ ! -b "$partition" ]]; then
        HandleValidationError "Invalid $description: '$partition' is not a valid block device"
        return 1
    fi
    
    return 0
}

ValidateHostname() {
    local hostname="$1"
    
    # Check hostname format (RFC 1123)
    if ! [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
        HandleValidationError "Invalid hostname: '$hostname' must contain only letters, numbers, and hyphens, and be 1-63 characters long"
        return 1
    fi
    
    return 0
}

ValidateUsername() {
    local username="$1"
    
    # Check username format (POSIX)
    if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]] || [[ ${#username} -gt 32 ]]; then
        HandleValidationError "Invalid username: '$username' must start with lowercase letter or underscore, contain only lowercase letters, numbers, underscore, and hyphen, and be max 32 characters"
        return 1
    fi
    
    # Check for reserved usernames
    local reserved_users=("root" "bin" "daemon" "adm" "lp" "sync" "shutdown" "halt" "mail" "operator" "games" "ftp" "nobody" "systemd-network" "systemd-resolve" "systemd-timesync" "systemd-coredump" "uuidd" "dbus" "polkitd")
    for reserved in "${reserved_users[@]}"; do
        if [[ "$username" == "$reserved" ]]; then
            HandleValidationError "Invalid username: '$username' is a reserved system username"
            return 1
        fi
    done
    
    return 0
}

# Safe input reading functions with validation and retry
ReadValidatedInput() {
    local prompt="$1"
    local validation_func="$2"  # name of a function that accepts a single arg (the input)
    local max_attempts="${3:-3}"
    local default_value="$4"
    local input=""
    local attempts=0
    
    while [[ $attempts -lt $max_attempts ]]; do
        if [[ -n "$default_value" ]]; then
            read -p "$prompt (default: $default_value): " input
            input="${input:-$default_value}"
        else
            read -p "$prompt: " input
        fi
        
        if [[ -n "$validation_func" ]] && declare -F "$validation_func" >/dev/null 2>&1; then
            if "$validation_func" "$input"; then
                echo "$input"
                return 0
            fi
        elif [[ -z "$validation_func" ]]; then
            echo "$input"
            return 0
        fi
        
        ((attempts++))
        if [[ $attempts -lt $max_attempts ]]; then
            PrintWarning "Please try again ($((max_attempts - attempts)) attempts remaining)"
        fi
    done
    
    HandleFatalError "Maximum validation attempts reached for: $prompt"
}

ReadValidatedChoice() {
    local prompt="$1"
    local max_choice="$2"
    local description="$3"
    local max_attempts="${4:-3}"
    local attempts=0
    local input=""
    while [[ $attempts -lt $max_attempts ]]; do
        read -p "$prompt: " input
        if ValidateChoice "$input" "$max_choice" "$description"; then
            echo "$input"
            return 0
        fi
        ((attempts++))
        if [[ $attempts -lt $max_attempts ]]; then
            PrintWarning "Please try again ($((max_attempts - attempts)) attempts remaining)"
        fi
    done
    HandleFatalError "Maximum validation attempts reached for: $prompt"
}

ReadValidatedYesNo() {
    local prompt="$1"
    local description="$2"
    local max_attempts="${3:-3}"
    local attempts=0
    local input=""
    while [[ $attempts -lt $max_attempts ]]; do
        read -p "$prompt (y/n): " input
        if ValidateYesNo "$input" "$description"; then
            echo "$input"
            return 0
        fi
        ((attempts++))
        if [[ $attempts -lt $max_attempts ]]; then
            PrintWarning "Please try again ($((max_attempts - attempts)) attempts remaining)"
        fi
    done
    HandleFatalError "Maximum validation attempts reached for: $prompt"
}

# Package installation verification functions
VerifyPackageInstalled() {
    local package="$1"
    local chroot_prefix="${2:-}"
    
    if [[ -n "$chroot_prefix" ]]; then
        arch-chroot /mnt pacman -Q "$package" >/dev/null 2>&1
    else
        pacman -Q "$package" >/dev/null 2>&1
    fi
}

InstallPackageWithVerification() {
    local package="$1"
    local description="${2:-$package}"
    local chroot_prefix="${3:-}"
    local max_attempts="${4:-3}"
    local attempts=0
    
    PrintStatus "Installing $description..."
    
    while [[ $attempts -lt $max_attempts ]]; do
        if [[ -n "$chroot_prefix" ]]; then
            if arch-chroot /mnt pacman -S --noconfirm "$package"; then
                if VerifyPackageInstalled "$package" "chroot"; then
                    PrintStatus "Successfully installed $description"
                    return 0
                else
                    PrintWarning "Package $package was installed but verification failed"
                fi
            fi
        else
            if pacman -S --noconfirm "$package"; then
                if VerifyPackageInstalled "$package"; then
                    PrintStatus "Successfully installed $description"
                    return 0
                else
                    PrintWarning "Package $package was installed but verification failed"
                fi
            fi
        fi
        
        ((attempts++))
        if [[ $attempts -lt $max_attempts ]]; then
            PrintWarning "Installation attempt $attempts failed for $description. Retrying... ($((max_attempts - attempts)) attempts remaining)"
            sleep 2
        fi
    done
    
    HandleRecoverableError "Failed to install $description after $max_attempts attempts"
    return 1
}

InstallPackageGroupWithVerification() {
    local packages=("$@")
    local failed_packages=()
    local chroot_prefix=""
    
    # Check if last argument is "chroot" to determine installation mode
    if [[ "${packages[-1]}" == "chroot" ]]; then
        chroot_prefix="chroot"
        unset 'packages[-1]'  # Remove "chroot" from packages array
    fi
    
    PrintStatus "Installing package group: ${packages[*]}"
    
    for package in "${packages[@]}"; do
        if ! InstallPackageWithVerification "$package" "$package" "$chroot_prefix"; then
            failed_packages+=("$package")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        PrintWarning "The following packages failed to install: ${failed_packages[*]}"
        return 1
    else
        PrintStatus "All packages in group installed successfully"
        return 0
    fi
}

# Safe pacman command wrapper with error checking
SafePacman() {
    local args=("$@")
    local chroot_mode=false
    local max_attempts=3
    local attempts=0
    
    # Check if first argument is "chroot"
    if [[ "${args[0]}" == "chroot" ]]; then
        chroot_mode=true
        args=("${args[@]:1}")  # Remove "chroot" from args
    fi
    
    while [[ $attempts -lt $max_attempts ]]; do
        if [[ "$chroot_mode" == true ]]; then
            if arch-chroot /mnt pacman "${args[@]}"; then
                return 0
            fi
        else
            if pacman "${args[@]}"; then
                return 0
            fi
        fi
        
        ((attempts++))
        if [[ $attempts -lt $max_attempts ]]; then
            PrintWarning "Pacman command failed. Retrying... ($((max_attempts - attempts)) attempts remaining)"
            sleep 2
        fi
    done
    
    HandleRecoverableError "Pacman command failed after $max_attempts attempts: ${args[*]}"
    return 1
}

# AUR helper installation with verification
InstallAurPackageWithVerification() {
    local package="$1"
    local description="${2:-$package}"
    local aur_helper="${3:-yay}"
    local max_attempts="${4:-3}"
    local attempts=0
    
    PrintStatus "Installing AUR package: $description..."
    
    while [[ $attempts -lt $max_attempts ]]; do
        if arch-chroot /mnt sudo -u "$USERNAME" "$aur_helper" -S --noconfirm "$package"; then
            if VerifyPackageInstalled "$package" "chroot"; then
                PrintStatus "Successfully installed AUR package: $description"
                return 0
            else
                PrintWarning "AUR package $package was installed but verification failed"
            fi
        fi
        
        ((attempts++))
        if [[ $attempts -lt $max_attempts ]]; then
            PrintWarning "AUR installation attempt $attempts failed for $description. Retrying... ($((max_attempts - attempts)) attempts remaining)"
            sleep 5
        fi
    done
    
    HandleRecoverableError "Failed to install AUR package $description after $max_attempts attempts"
    return 1
}

# Password collection functions
CollectPasswords() {
    PrintHeader "Password Setup"
    PrintStatus "Setting up user passwords for automated installation"
    
    # Collect root password
    while [[ -z "$ROOT_PASSWORD" ]]; do
        echo -n "Enter root password: "
        read -s ROOT_PASSWORD
        echo
        
        if [[ ${#ROOT_PASSWORD} -lt 8 ]]; then
            PrintWarning "Password must be at least 8 characters long"
            ROOT_PASSWORD=""
            continue
        fi
        
        echo -n "Confirm root password: "
        read -s root_confirm
        echo
        
        if [[ "$ROOT_PASSWORD" != "$root_confirm" ]]; then
            PrintWarning "Passwords do not match"
            ROOT_PASSWORD=""
        fi
    done
    
    # Collect user password
    while [[ -z "$USER_PASSWORD" ]]; do
        echo -n "Enter password for user '$USERNAME': "
        read -s USER_PASSWORD
        echo
        
        if [[ ${#USER_PASSWORD} -lt 8 ]]; then
            PrintWarning "Password must be at least 8 characters long"
            USER_PASSWORD=""
            continue
        fi
        
        echo -n "Confirm password for user '$USERNAME': "
        read -s user_confirm
        echo
        
        if [[ "$USER_PASSWORD" != "$user_confirm" ]]; then
            PrintWarning "Passwords do not match"
            USER_PASSWORD=""
        fi
    done
    
    PrintStatus "Passwords collected successfully"
}

# Function to set passwords non-interactively
SetPasswordsNonInteractive() {
    local root_password="$1"
    local user_password="$2"
    local username="$3"
    
    # Set root password using chpasswd
    echo "root:$root_password" | arch-chroot /mnt chpasswd
    
    # Set user password using chpasswd
    echo "$username:$user_password" | arch-chroot /mnt chpasswd
}

# Function to show help
ShowHelp() {
    cat << EOF
PCMR Arch Linux Installation Script
ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --config FILE          Load configuration from specified JSON file
    --standard             Ignore config file and use interactive installation
    --dual-boot-gpt        Modern GPT UEFI dual boot mode (existing Windows)
    --dual-boot-new        Fresh install EFI for new Windows + Arch dual boot
    --zen-kernel           Use zen kernel instead of standard kernel
    --no-tui               Disable TUI; use plain log output
    --help, -h             Show this help message

EXAMPLES:
    $0 --config Configs/Zen.json
    $0 --standard
    $0 --dual-boot-gpt --zen-kernel

CONFIGURATION:
    The script can load configuration from a file.
    Available configurations:
    - Configs/Zen.json: Performance gaming setup (stable default)

DUAL BOOT MODES:
    --dual-boot-gpt        For existing Windows UEFI installations
    --dual-boot-new        For fresh dual boot installations

FILESYSTEMS (stable policy):
    ext4 (effective)       Stable, compatible, used on stable
    zfs/btrfs (requested)  Auto-fallback to ext4 on stable

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
    - Secure Boot (signing deferred on stable; fresh uses systemd-boot unsigned; dual-boot uses GRUB without SB)

For more information, see README.md
EOF
}

# Function to parse JSON configuration files
ParseJsonConfig() {
    local config_file="$1"
    local json_content
    
    if [[ ! -f "$config_file" ]]; then
        HandleFatalError "Configuration file not found: $config_file"
    fi
    
    # Read JSON content
    json_content=$(cat "$config_file")
    
    # Simple JSON parsing using grep and sed (avoiding jq dependency)
    # Parse system settings
    USERNAME=$(echo "$json_content" | grep -o '"default_username"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"default_username"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
    HOSTNAME=$(echo "$json_content" | grep -o '"default_hostname"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"default_hostname"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
    TIMEZONE=$(echo "$json_content" | grep -o '"default_timezone"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"default_timezone"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
    
    # Parse installation settings
    DUAL_BOOT_MODE=$(echo "$json_content" | grep -o '"dual_boot_mode"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"dual_boot_mode"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
    USE_ZEN_KERNEL=$(echo "$json_content" | grep -o '"kernel_variant"[[:space:]]*:[[:space:]]*"zen"' >/dev/null && echo "true" || echo "false")
    FILESYSTEM=$(echo "$json_content" | grep -o '"default_filesystem"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"default_filesystem"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
    DESKTOP_ENVIRONMENT=$(echo "$json_content" | grep -o '"default_desktop"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"default_desktop"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
    INSTALL_GAMING=$(echo "$json_content" | grep -o '"enable_gaming"[[:space:]]*:[[:space:]]*true' >/dev/null && echo "true" || echo "false")
    ENABLE_SNAPSHOTS=false
    
    # Parse power management
    INSTALL_POWER_MGMT=$(echo "$json_content" | grep -o '"enable_power_management"[[:space:]]*:[[:space:]]*true' >/dev/null && echo "true" || echo "false")
    
    # Parse hardware settings
    ENABLE_HARDWARE_FIXES=$(echo "$json_content" | grep -o '"enable_hardware_fixes"[[:space:]]*:[[:space:]]*true' >/dev/null && echo "true" || echo "false")
    ENABLE_SECURE_BOOT=$(echo "$json_content" | grep -o '"enable_secure_boot"[[:space:]]*:[[:space:]]*true' >/dev/null && echo "true" || echo "false")
    
    # Parse recovery settings
    ENABLE_ERROR_RECOVERY=$(echo "$json_content" | grep -o '"enable_error_recovery"[[:space:]]*:[[:space:]]*true' >/dev/null && echo "true" || echo "false")
    ENABLE_FILESYSTEM_FALLBACK=$(echo "$json_content" | grep -o '"enable_filesystem_fallback"[[:space:]]*:[[:space:]]*true' >/dev/null && echo "true" || echo "false")
    ENABLE_FRESH_REINSTALL=$(echo "$json_content" | grep -o '"enable_fresh_reinstall"[[:space:]]*:[[:space:]]*true' >/dev/null && echo "true" || echo "false")
    ENABLE_DETACHED_MODE=$(echo "$json_content" | grep -o '"enable_detached_mode"[[:space:]]*:[[:space:]]*true' >/dev/null && echo "true" || echo "false")
    
    # Set defaults for empty values
    USERNAME=${USERNAME:-$DEFAULT_USERNAME}
    HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}
    TIMEZONE=${TIMEZONE:-$DEFAULT_TIMEZONE}
    FILESYSTEM="ext4"
    # Enforce omarchy desktop regardless of config
    DESKTOP_ENVIRONMENT="omarchy"
}

# Function to load default configuration
LoadDefaultConfig() {
    local defaults_file="$(dirname "$0")/Configs/Zen.json"
    
    if [[ -f "$defaults_file" ]]; then
        PrintStatus "Loading default configuration..."
        ParseJsonConfig "$defaults_file"
    else
        PrintWarning "Default configuration (Zen.json) not found, using hardcoded defaults"
    fi
}

# Function to load configuration from file
LoadConfig() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        HandleFatalError "Configuration file not found: $config_file"
    fi
    
    PrintStatus "Loading configuration from: $config_file"
    
    # Require JSON configuration files only
    if grep -q '^[[:space:]]*{' "$config_file"; then
        ParseJsonConfig "$config_file"
    else
        HandleFatalError "Unsupported configuration format. Please provide a JSON config file."
    fi
    
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
    
    # Device guard is enforced early in Main()

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

# Function to offer recovery options
OfferRecoveryOptions() {
    local failure_phase="$1"
    local error_message="$2"
    
    PrintError "Installation failed at phase: $failure_phase"
    PrintError "Error: $error_message"
    
    if [[ "$ENABLE_FRESH_REINSTALL" == "true" ]]; then
        echo ""
        PrintStatus "Recovery Options:"
        echo "1) Clean up and restart fresh installation"
        echo "2) Try to repair and continue from current phase"
        echo "3) Clean up and exit (manual recovery)"
        echo ""
        
        read -p "Choose recovery option (1-3): " recovery_choice
        
        case "$recovery_choice" in
            1)
                PrintStatus "Starting fresh reinstall..."
                PerformFullCleanup
                ResetInstallationState
                RestartInstallation
                ;;
            2)
                if [[ "$RETRY_COUNT" -lt "$MAX_RETRY_ATTEMPTS" ]]; then
                    PrintStatus "Attempting repair and retry..."
                    ((RETRY_COUNT++))
                    PerformPartialCleanup
                    return 0  # Continue installation
                else
                    PrintError "Maximum retry attempts reached. Switching to fresh reinstall."
                    PerformFullCleanup
                    ResetInstallationState
                    RestartInstallation
                fi
                ;;
            3)
                PrintStatus "Performing cleanup and exiting..."
                PerformFullCleanup
                exit 1
                ;;
            *)
                PrintWarning "Invalid choice. Defaulting to fresh reinstall."
                PerformFullCleanup
                ResetInstallationState
                RestartInstallation
                ;;
        esac
    else
        PerformFullCleanup
        exit 1
    fi
}

# Function to perform full cleanup for fresh reinstall
PerformFullCleanup() {
    PrintStatus "Performing comprehensive cleanup..."
    
    # Unmount filesystems with timeout
    timeout "$CLEANUP_TIMEOUT" umount -R /mnt 2>/dev/null || {
        PrintWarning "Forced unmount due to timeout"
        umount -l /mnt 2>/dev/null || true
    }
    
    # Destroy ZFS pool if created
    if [[ "$FILESYSTEM_CREATED" == "zfs" ]]; then
        zpool destroy -f zroot 2>/dev/null || true
        PrintStatus "ZFS pool destroyed"
    fi
    
    # Remove Btrfs subvolumes if created
    if [[ "$FILESYSTEM_CREATED" == "btrfs" ]]; then
        btrfs subvolume delete /mnt/@ 2>/dev/null || true
        btrfs subvolume delete /mnt/@home 2>/dev/null || true
        btrfs subvolume delete /mnt/@var 2>/dev/null || true
        btrfs subvolume delete /mnt/@snapshots 2>/dev/null || true
        PrintStatus "Btrfs subvolumes removed"
    fi
    
    # Clean up any partial package installations
    if [[ -d "/mnt/var/lib/pacman" ]]; then
        rm -rf /mnt/var/lib/pacman/db.lck 2>/dev/null || true
        PrintStatus "Package manager lock files removed"
    fi
    
    # Reset swap if activated
    if [[ -n "$SWAP_PART" ]] && swapon --show | grep -q "$SWAP_PART"; then
        swapoff "$SWAP_PART" 2>/dev/null || true
        PrintStatus "Swap deactivated"
    fi
    
    PrintStatus "Full cleanup completed"
}

# Function to perform partial cleanup for retry
PerformPartialCleanup() {
    PrintStatus "Performing partial cleanup for retry..."
    
    # Only unmount and reset current phase state
    umount -R /mnt 2>/dev/null || true
    
    # Reset filesystem state but keep partitions
    FILESYSTEM_CREATED=""
    CURRENT_FILESYSTEM=""
    
    PrintStatus "Partial cleanup completed"
}

# Function to reset installation state
ResetInstallationState() {
    INSTALLATION_STARTED=false
    BASE_SYSTEM_INSTALLED=false
    INSTALLATION_PHASE=""
    RETRY_COUNT=0
    FILESYSTEM_CREATED=""
    CURRENT_FILESYSTEM=""
    
    # Reset partition variables but keep disk selection
    ROOT_PART=""
    SWAP_PART=""
    # Keep EFI_PART and DISK_DEVICE for consistency
    
    PrintStatus "Installation state reset"
}

# Function to restart installation
RestartInstallation() {
    PrintStatus "Restarting installation process..."
    
    # Offer to change configuration
    echo ""
    read -p "Would you like to use a different configuration? (y/n): " change_config
    
    if [[ "$change_config" =~ ^[Yy] ]]; then
        echo "Available configurations:"
        echo "1) Zen.json (stable default)"
        echo "2) Keep current configuration"
        
        read -p "Choose configuration (1-2): " config_choice
        
        case "$config_choice" in
            1) LoadConfig "$(dirname "$0")/Configs/Zen.json" ;;
            2) PrintStatus "Keeping current configuration" ;;
            *) PrintWarning "Invalid choice, keeping current configuration" ;;
        esac
    fi
    
    # Restart from disk management phase
    INSTALLATION_PHASE="disk_management"
    INSTALLATION_STARTED=true
    
    # Re-run the main installation logic
    CoreInstallation
}

# Enhanced cleanup on failure with recovery options
CleanupOnFailure() {
    if [[ "$INSTALLATION_STARTED" == true ]]; then
        OfferRecoveryOptions "$INSTALLATION_PHASE" "Installation script terminated unexpectedly"
    fi
}

# Function to enable detached installation mode
EnableDetachedMode() {
    if [[ "$ENABLE_DETACHED_MODE" != "true" ]]; then
        PrintWarning "Detached mode is not enabled in configuration"
        return 1
    fi
    
    PrintStatus "Enabling detached installation mode..."
    PrintStatus "You can now safely detach from this session."
    PrintStatus "The installation will continue in the background."
    echo ""
    PrintStatus "To reattach later, use: screen -r pcmr-install"
    PrintStatus "To check progress, use: tail -f /tmp/pcmr-install.log"
    echo ""
    
    # Ensure 'screen' is available
    if ! command -v screen >/dev/null 2>&1; then
        PrintWarning "Detached mode requires 'screen', which is not available in this environment. Skipping detach."
        return 1
    fi

    # Start screen session for detached mode
    screen -dmS pcmr-install bash -c "
        # Redirect all output to log file
        exec > >(tee -a /tmp/pcmr-install.log)
        exec 2>&1
        
        # Continue installation
        DETACHED_MODE=true
        CoreInstallation
    "
    
    DETACHED_PID=$(screen -list | grep pcmr-install | awk '{print $1}' | cut -d. -f1)
    
    if [[ -n "$DETACHED_PID" ]]; then
        PrintStatus "Installation detached successfully (PID: $DETACHED_PID)"
        PrintStatus "Session name: pcmr-install"
        echo ""
        PrintStatus "Commands to manage detached installation:"
        echo "  Reattach:     screen -r pcmr-install"
        echo "  Check status: tail -f /tmp/pcmr-install.log"
        echo "  Kill session: screen -S pcmr-install -X quit"
        echo ""
        exit 0
    else
        PrintError "Failed to start detached session"
        return 1
    fi
}

# Function to check if running in detached mode
IsDetachedMode() {
    [[ "$DETACHED_MODE" == "true" ]] || [[ -n "$STY" ]]
}

# Function to offer detach option during installation
OfferDetachOption() {
    local phase="$1"
    
    if [[ "$ENABLE_DETACHED_MODE" == "true" ]] && [[ "$DETACHED_MODE" != "true" ]]; then
        echo ""
        PrintStatus "Current phase: $phase"
        PrintStatus "You can detach from this installation to do other tasks."
        echo ""
        read -p "Would you like to detach now? (y/n): " detach_choice
        
        if [[ "$detach_choice" =~ ^[Yy] ]]; then
            EnableDetachedMode
        fi
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
    
    # If in detached mode, provide reattach instructions
    if IsDetachedMode; then
        echo ""
        PrintStatus "Installation completed in detached mode."
        PrintStatus "You can now safely exit this screen session."
        PrintStatus "Use 'screen -S pcmr-install -X quit' to close this session."
    fi
}

# Main function
Main() {
    # Set up error handling
    trap CleanupOnFailure ERR
    
    # Enforce device guard early: AMD Ryzen Strix Halo only
    local cpu_info=""
    if command -v lscpu >/dev/null 2>&1; then
        cpu_info=$(lscpu 2>/dev/null | tr '[:upper:]' '[:lower:]')
    else
        cpu_info=$(cat /proc/cpuinfo 2>/dev/null | tr '[:upper:]' '[:lower:]')
    fi
    if [[ -z "$cpu_info" ]]; then
        HandleFatalError "Unable to detect CPU information. This installer is restricted to AMD Ryzen Strix Halo platforms."
    fi
    # Require AMD and either explicit Strix Halo mention or Ryzen AI 395 identifier
    if ! echo "$cpu_info" | grep -q "amd" || ! echo "$cpu_info" | grep -Eiq "strix[[:space:]-]?halo|ryzen[[:space:]]*ai|\b395\b"; then
        HandleFatalError "Unsupported device/CPU. This installer is restricted to AMD Ryzen Strix Halo platforms."
    fi
    # Soft GPU presence check (non-fatal)
    if command -v lspci >/dev/null 2>&1; then
        if ! lspci | tr '[:upper:]' '[:lower:]' | grep -Eiq "amdgpu|advanced micro devices|amd.*graphics"; then
            PrintWarning "AMDGPU device not detected. Proceeding due to CPU match, but installation may fail."
        fi
    fi
    
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
            --no-tui)
                FORCE_NO_TUI=true
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
    
    # Load default configuration first
    LoadDefaultConfig
    
    # Load configuration if requested
    if [[ "$use_config" == true ]]; then
        if [[ -z "$config_file" ]]; then
            config_file="Configs/Zen.json"
        fi
        LoadConfig "$config_file"
    else
        PrintStatus "Using standard installation mode with defaults"
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

    # Enforce Secure Boot policy for dual-boot with existing OS
    if [[ "$DUAL_BOOT_MODE" == "gpt" && "$ENABLE_SECURE_BOOT" == "true" ]]; then
        PrintWarning "Dual-boot with existing OS detected. Disabling Secure Boot for compatibility (GRUB will be used)."
        ENABLE_SECURE_BOOT=false
    fi
    
    # Validate prerequisites
    ValidatePrerequisites
    
    # Show installation summary
    ShowSummary
    
    # Collect passwords for automated installation
    CollectPasswords
    
    INSTALLATION_STARTED=true
    INSTALLATION_PHASE="initialization"
    
    # Offer detach option before starting intensive operations
    if [[ "$ENABLE_DETACHED_MODE" == "true" ]]; then
        OfferDetachOption "Pre-Installation Setup"
    fi
    
    # Load TUI display system (unless disabled)
    if [[ "$FORCE_NO_TUI" == true ]]; then
        TUI_ENABLED=false
        PrintStatus "TUI disabled via --no-tui; using standard output"
    else
        if [[ -f "$(dirname "$0")/Modules/TuiDisplay.sh" ]]; then
            source "$(dirname "$0")/Modules/TuiDisplay.sh"
            TUI_ENABLED=true
            init_tui
            
            # Set TUI mode based on how script was called
            if [[ "$use_config" == true ]]; then
                local config_basename=$(basename "$config_file")
                config_basename=${config_basename%.json}
                config_basename=${config_basename%.conf}
                tui_set_mode "CONFIG" "$config_basename"
            elif [[ "$#" -eq 0 ]]; then
                tui_set_mode "AUTO" ""
            else
                tui_set_mode "MANUAL" ""
            fi
        else
            TUI_ENABLED=false
            PrintWarning "TUI display not available, using standard output"
        fi
    fi
    
    # Load and execute installation modules
    LoadModule "DiskManagement"
    LoadModule "FilesystemSetup"
    LoadModule "CoreInstallation"
    LoadModule "Bootloader"
    # Optional: ASUS hardware enablement (safe subset)
    if [[ "$ENABLE_HARDWARE_FIXES" == true ]]; then
        if [[ -f "$(dirname "$0")/Modules/HardwareEnablement.sh" ]]; then
            source "$(dirname "$0")/Modules/HardwareEnablement.sh"
            HWE_AVAILABLE=true
        else
            HWE_AVAILABLE=false
        fi
    fi
    
    # Run installation sequence
    if [[ "$TUI_ENABLED" == true ]]; then
        add_log_message "Starting PCMR Arch Linux Installation"
        add_log_message "Configuration: ${DUAL_BOOT_MODE:-Auto} | $([ "$USE_ZEN_KERNEL" == true ] && echo "Zen" || echo "Standard") kernel"
        add_log_message "Filesystem: $FILESYSTEM | Desktop: $DESKTOP_ENVIRONMENT"
    fi
    
    # Execute installation phases with resume support
    run_phase "disk" disk_management_setup
    run_phase "fs" filesystem_setup
    run_phase "base" CoreInstallation
    BASE_SYSTEM_INSTALLED=true
    # Install bootloader before hardening
    run_phase "bootloader" bootloader_setup
    
    # Load and run system configuration
    # Optional hardware enablement (safe subset only on stable core)
    if [[ "$ENABLE_HARDWARE_FIXES" == true && "$HWE_AVAILABLE" == true ]]; then
        run_phase "hwe" hardware_enablement_setup
    fi

    # Stable: skip advanced modules (security hardening, performance, monitoring, backup)
    
    if [[ "$TUI_ENABLED" == true ]]; then
        add_log_message "🎉 Installation completed successfully!"
        add_log_message "System ready for first boot"
        cleanup_tui
    fi
    
    CleanupAndFinish
}

# Run main function with all arguments
Main "$@"
