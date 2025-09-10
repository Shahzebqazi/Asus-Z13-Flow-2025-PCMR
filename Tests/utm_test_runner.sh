#!/bin/bash
# UTM Test Runner for Arch Linux Installation
# Author: sqazi
# Version: 1.0.0
# Date: September 10, 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if UTM is installed
check_utm() {
    if ! command -v utm &> /dev/null; then
        print_error "UTM is not installed. Install with: brew install --cask utm"
        exit 1
    fi
    print_status "UTM is available"
}

# Check if Arch ISO exists
check_arch_iso() {
    local iso_path="$1"
    if [[ ! -f "$iso_path" ]]; then
        print_error "Arch Linux ISO not found at: $iso_path"
        print_status "Download from: https://archlinux.org/download/"
        exit 1
    fi
    print_status "Arch Linux ISO found: $iso_path"
}

# Create UTM VM configuration
create_vm_config() {
    local vm_name="$1"
    local iso_path="$2"
    local memory="$3"
    local cpu_cores="$4"
    local disk_size="$5"
    
    print_header "Creating UTM VM Configuration"
    
    # Create VM configuration directory
    local config_dir="$HOME/.utm/vms/$vm_name"
    mkdir -p "$config_dir"
    
    # Create VM configuration file
    cat > "$config_dir/config.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>name</key>
    <string>$vm_name</string>
    <key>architecture</key>
    <string>x86_64</string>
    <key>memory</key>
    <integer>$memory</integer>
    <key>cpu_cores</key>
    <integer>$cpu_cores</integer>
    <key>disk_size</key>
    <integer>$disk_size</integer>
    <key>iso_path</key>
    <string>$iso_path</string>
</dict>
</plist>
EOF
    
    print_status "VM configuration created: $config_dir/config.plist"
}

# Run installation test
run_installation_test() {
    local vm_name="$1"
    local script_url="$2"
    
    print_header "Running Installation Test"
    
    print_status "Starting VM: $vm_name"
    print_status "Test script: $script_url"
    
    # Note: This would require UTM CLI or manual VM management
    # For now, we'll just validate the configuration
    print_warning "Manual VM testing required - UTM CLI not available"
    print_status "1. Start VM in UTM"
    print_status "2. Boot from Arch Linux ISO"
    print_status "3. Run: curl -L $script_url | bash"
    print_status "4. Follow installation prompts"
    print_status "5. Verify system boots correctly"
}

# Main function
main() {
    print_header "UTM Test Runner for Arch Linux Installation"
    
    # Configuration
    local vm_name="${1:-ArchTest-Z13}"
    local iso_path="${2:-$HOME/Downloads/archlinux-x86_64.iso}"
    local memory="${3:-4096}"
    local cpu_cores="${4:-4}"
    local disk_size="${5:-53687091200}"  # 50GB
    local script_url="${6:-https://github.com/Shahzebqazi/Asus-Z13-Flow-2025-PCMR/raw/main/Install.sh}"
    
    # Run checks
    check_utm
    check_arch_iso "$iso_path"
    
    # Create VM configuration
    create_vm_config "$vm_name" "$iso_path" "$memory" "$cpu_cores" "$disk_size"
    
    # Run installation test
    run_installation_test "$vm_name" "$script_url"
    
    print_status "UTM test runner completed successfully"
}

# Run main function with arguments
main "$@"
