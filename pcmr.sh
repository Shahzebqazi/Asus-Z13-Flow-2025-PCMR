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
# Resolve script and repository root
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
if [[ "$SCRIPT_PATH" == "-" || "$SCRIPT_PATH" == "bash" || "$SCRIPT_PATH" == "/dev/fd"* ]]; then
    SCRIPT_DIR="$(pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
fi
SOURCE_DIR="$SCRIPT_DIR"
# Repo root is one level up from Source when running from Source/pcmr.sh
REPO_ROOT="$(cd "$SOURCE_DIR/.." 2>/dev/null && pwd)"

# Paths inside repo
MODULES_DIR="$SOURCE_DIR/Modules"
# Determine a safe input device for interactive reads
# Use /dev/stdin for most reliable input handling
TTY_INPUT="/dev/stdin"
# For script execution in different contexts, ensure proper terminal handling
if [[ -t 0 ]] && [[ -e /dev/tty ]]; then
    TTY_INPUT="/dev/tty"
fi

# Global variables
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

# Password policy
MIN_PASSWORD_LENGTH=4

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
    INSTALLATION_PHASE="$phase_name"
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
            read -p "$prompt (default: $default_value): " input < "$TTY_INPUT" || true
            input="${input:-$default_value}"
        else
            read -p "$prompt: " input < "$TTY_INPUT" || true
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
        read -p "$prompt: " input < "$TTY_INPUT" || true
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
        read -p "$prompt (y/n): " input < "$TTY_INPUT" || true
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
        read -s ROOT_PASSWORD < "$TTY_INPUT" || true
        echo
        
        if [[ ${#ROOT_PASSWORD} -lt ${MIN_PASSWORD_LENGTH} ]]; then
            PrintWarning "Password must be at least ${MIN_PASSWORD_LENGTH} characters long"
            ROOT_PASSWORD=""
            continue
        fi
        
        echo -n "Confirm root password: "
        read -s root_confirm < "$TTY_INPUT" || true
        echo
        
        if [[ "$ROOT_PASSWORD" != "$root_confirm" ]]; then
            PrintWarning "Passwords do not match"
            ROOT_PASSWORD=""
        fi
    done
    
    # Collect user password
    while [[ -z "$USER_PASSWORD" ]]; do
        echo -n "Enter password for user '$USERNAME': "
        read -s USER_PASSWORD < "$TTY_INPUT" || true
        echo
        
        if [[ ${#USER_PASSWORD} -lt ${MIN_PASSWORD_LENGTH} ]]; then
            PrintWarning "Password must be at least ${MIN_PASSWORD_LENGTH} characters long"
            USER_PASSWORD=""
            continue
        fi
        
        echo -n "Confirm password for user '$USERNAME': "
        read -s user_confirm < "$TTY_INPUT" || true
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
    $0 --config "$REPO_ROOT/Configs/Zen.json"
    $0 --standard
    $0 --dual-boot-gpt --zen-kernel

CONFIGURATION:
    The script can load configuration from a file.
    Available configurations:
    - $REPO_ROOT/Configs/Zen.json: Performance gaming setup (stable default)

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

# Removed self-bootstrap complexity

# Function to parse JSON configuration files
ParseJsonConfig() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        HandleFatalError "Configuration file not found: $config_file"
    fi
    
    # Install jq if not available
    if ! command -v jq >/dev/null 2>&1; then
        PrintStatus "Installing jq for JSON parsing..."
        pacman -Sy --noconfirm jq || HandleFatalError "Failed to install jq"
    fi
    
    # Parse JSON using jq with proper error handling
    if ! jq empty "$config_file" 2>/dev/null; then
        HandleFatalError "Invalid JSON in configuration file: $config_file"
    fi
    
    # Parse system settings
    USERNAME=$(jq -r '.system.default_username // ""' "$config_file")
    HOSTNAME=$(jq -r '.system.default_hostname // ""' "$config_file")
    TIMEZONE=$(jq -r '.system.default_timezone // ""' "$config_file")
    
    # Parse installation settings
    DUAL_BOOT_MODE=$(jq -r '.installation.dual_boot_mode // ""' "$config_file")
    local kernel_variant=$(jq -r '.installation.kernel_variant // ""' "$config_file")
    USE_ZEN_KERNEL=$([ "$kernel_variant" = "zen" ] && echo "true" || echo "false")
    FILESYSTEM=$(jq -r '.installation.default_filesystem // "ext4"' "$config_file")
    DESKTOP_ENVIRONMENT=$(jq -r '.installation.default_desktop // "omarchy"' "$config_file")
    INSTALL_GAMING=$(jq -r '.installation.enable_gaming // false' "$config_file")
    ENABLE_SNAPSHOTS=$(jq -r '.installation.enable_snapshots // false' "$config_file")
    
    # Parse power management
    INSTALL_POWER_MGMT=$(jq -r '.power.enable_power_management // true' "$config_file")
    
    # Parse hardware settings
    ENABLE_HARDWARE_FIXES=$(jq -r '.hardware.enable_hardware_fixes // true' "$config_file")
    ENABLE_SECURE_BOOT=$(jq -r '.installation.enable_secure_boot // false' "$config_file")
    
    # Parse recovery settings (simplified)
    ENABLE_ERROR_RECOVERY="true"
    ENABLE_FILESYSTEM_FALLBACK="true"
    ENABLE_FRESH_REINSTALL="true"
    
    # Set defaults for empty values
    USERNAME=${USERNAME:-$DEFAULT_USERNAME}
    HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}
    TIMEZONE=${TIMEZONE:-$DEFAULT_TIMEZONE}
    
    # Enforce omarchy desktop regardless of config
    DESKTOP_ENVIRONMENT="omarchy"
}

# Function to load default configuration
LoadDefaultConfig() {
    local defaults_file="$REPO_ROOT/Configs/Zen.json"
    
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
        
        # Enhanced EFI partition detection with better error handling
        local efi_candidates=()
        local best_efi_part=""
        local best_efi_size=0
        
        # Use more robust partition detection
        if command -v lsblk >/dev/null 2>&1; then
            while IFS= read -r line; do
                local part_name=$(echo "$line" | awk '{print $1}')
                local part_type=$(echo "$line" | awk '{print $2}')
                # Check for EFI System Partition GUID (case insensitive)
                if [[ "$part_type" =~ ^[cC]12[aA]7328-[fF]81[fF]-11[dD]2-[bB][aA]4[bB]-00[aA]0[cC]93[eE][cC]93[bB]$ ]]; then
                    efi_candidates+=("$part_name")
                fi
            done < <(lsblk -rno NAME,PARTTYPE 2>/dev/null || true)
        fi
        
        # Fallback detection using fdisk if lsblk fails
        if [[ ${#efi_candidates[@]} -eq 0 ]] && command -v fdisk >/dev/null 2>&1; then
            PrintStatus "Fallback: Using fdisk for EFI partition detection"
            while IFS= read -r disk; do
                if [[ -b "$disk" ]]; then
                    while IFS= read -r line; do
                        if echo "$line" | grep -qi "EFI System"; then
                            local part_num=$(echo "$line" | awk '{print $1}')
                            efi_candidates+=("${disk}${part_num}")
                        fi
                    done < <(fdisk -l "$disk" 2>/dev/null | grep "^/dev" || true)
                fi
            done < <(lsblk -rno NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}' || true)
        fi
        
        # Find the best EFI partition (largest with sufficient space)
        for efi_part in "${efi_candidates[@]}"; do
            if [[ -b "/dev/$efi_part" ]]; then
                local efi_size=$(lsblk -b "/dev/$efi_part" -o SIZE --noheadings | head -1)
                local efi_size_mb=$((efi_size / 1024 / 1024))
                
                if [[ $efi_size_mb -ge 100 && $efi_size_mb -gt $best_efi_size ]]; then
                    best_efi_part="$efi_part"
                    best_efi_size=$efi_size_mb
                fi
            fi
        done
        
        if [[ -n "$best_efi_part" ]]; then
            PrintStatus "Found suitable EFI partition: $best_efi_part (${best_efi_size}MB)"
            EFI_PART="/dev/$best_efi_part"
        elif [[ ${#efi_candidates[@]} -gt 0 ]]; then
            # Found EFI partitions but all too small
            local first_efi="${efi_candidates[0]}"
            local first_size=$(lsblk -b "/dev/$first_efi" -o SIZE --noheadings | head -1)
            local first_size_mb=$((first_size / 1024 / 1024))
            HandleFatalError "EFI partition $first_efi is only ${first_size_mb}MB. This is too small for dual boot. Please resize EFI partition to at least 100MB before continuing. See: https://wiki.archlinux.org/title/Dual_boot_with_Windows#The_EFI_system_partition_created_by_Windows_Setup_is_too_small"
        else
            PrintStatus "No EFI partition found, using --dual-boot-new mode"
            DUAL_BOOT_MODE="new"
        fi
        
        if [[ -n "$best_efi_part" ]]; then
            # Check if Windows is installed
            local windows_part=$(lsblk -rno NAME,FSTYPE | grep -i "ntfs" | head -1 | cut -d' ' -f1)
            
            if [[ -n "$windows_part" ]]; then
                PrintStatus "Found Windows installation, using --dual-boot-gpt mode"
                DUAL_BOOT_MODE="gpt"
            else
                PrintStatus "No Windows found, using --dual-boot-new mode"
                DUAL_BOOT_MODE="new"
            fi
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
    read -r < "$TTY_INPUT" || true
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

# Simplified error handling - just cleanup and exit
OfferRecoveryOptions() {
    local failure_phase="$1"
    local error_message="$2"
    
    PrintError "Installation failed at phase: $failure_phase"
    PrintError "Error: $error_message"
    PrintStatus "Performing cleanup..."
    
    SimpleCleanup
    exit 1
}

# Simplified cleanup function
SimpleCleanup() {
    PrintStatus "Performing cleanup..."
    
    # Unmount filesystems 
    umount -R /mnt 2>/dev/null || umount -l /mnt 2>/dev/null || true
    
    # Destroy ZFS pool if created
    if [[ "$FILESYSTEM_CREATED" == "zfs" ]]; then
        zpool destroy -f zroot 2>/dev/null || true
    fi
    
    # Reset swap if activated
    if [[ -n "$SWAP_PART" ]]; then
        swapoff "$SWAP_PART" 2>/dev/null || true
    fi
    
    PrintStatus "Cleanup completed"
}

# Removed complex restart and retry logic - keep it simple

# Simplified cleanup on failure
CleanupOnFailure() {
    local err_code=$?
    PrintError "Exit code: ${err_code}"
    PrintError "Last command: ${BASH_COMMAND}"
    if [[ "$INSTALLATION_STARTED" == true ]]; then
        PrintError "Installation failed at phase: ${INSTALLATION_PHASE:-unknown}"
        SimpleCleanup
    fi
    exit 1
}

# Removed detached mode complexity - not needed for simple installation

# Function to cleanup and finish
CleanupAndFinish() {
    PrintHeader "Finalizing Installation"
    
    # Unmount filesystems
    umount -R /mnt 2>/dev/null || true
    
    PrintStatus "Installation completed successfully!"
    PrintStatus "You can now reboot into your new Arch Linux installation"
    PrintStatus "Remember to remove the installation media before rebooting"
}

# Main function
Main() {
    # Set up error handling
    trap CleanupOnFailure ERR
    
    # Enforce device guard: AMD systems (with preference for Strix Halo)
    local cpu_info=""
    if command -v lscpu >/dev/null 2>&1; then
        cpu_info=$(lscpu 2>/dev/null | tr '[:upper:]' '[:lower:]')
    else
        cpu_info=$(cat /proc/cpuinfo 2>/dev/null | tr '[:upper:]' '[:lower:]')
    fi
    if [[ -z "$cpu_info" ]]; then
        PrintWarning "Unable to detect CPU information. Proceeding with installation."
    else
        # Check for AMD processors
        if echo "$cpu_info" | grep -q "amd"; then
            # Check for Strix Halo specifically
            if echo "$cpu_info" | grep -Eiq "strix[[:space:]-]?halo|ryzen[[:space:]]*ai[[:space:]]*max|395|8060s"; then
                PrintStatus "Detected AMD Strix Halo platform - optimal compatibility"
            else
                PrintStatus "Detected AMD platform - good compatibility expected"
            fi
        else
            PrintWarning "Non-AMD processor detected. This installer is optimized for AMD systems, particularly Strix Halo. Proceeding but some features may not work correctly."
        fi
    fi
    
    # Soft GPU presence check (non-fatal)
    if command -v lspci >/dev/null 2>&1; then
        if lspci | tr '[:upper:]' '[:lower:]' | grep -Eiq "amdgpu|advanced micro devices|amd.*graphics"; then
            PrintStatus "AMD GPU detected"
        else
            PrintWarning "AMD GPU not detected. Some hardware optimizations may not apply."
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
            config_file="$REPO_ROOT/Configs/Zen.json"
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

    # Ensure required modules are available
    if [[ ! -f "$MODULES_DIR/DiskManagement.sh" ]]; then
        HandleFatalError "Required modules not found. Please run this script from the repository root or ensure modules are available."
    fi

    # Show installation summary
    ShowSummary
    
    # Collect passwords for automated installation
    CollectPasswords
    
    INSTALLATION_STARTED=true
    INSTALLATION_PHASE="initialization"
    
    # Removed detached mode offer
    
    # Load TUI display system (unless disabled)
    if [[ "$FORCE_NO_TUI" == true ]]; then
        TUI_ENABLED=false
        PrintStatus "TUI disabled via --no-tui; using standard output"
    else
        if [[ -f "$MODULES_DIR/TuiDisplay.sh" ]]; then
            source "$MODULES_DIR/TuiDisplay.sh"
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
        if [[ -f "$MODULES_DIR/HardwareEnablement.sh" ]]; then
            source "$MODULES_DIR/HardwareEnablement.sh"
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
