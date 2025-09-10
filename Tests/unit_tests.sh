#!/bin/bash
# Unit Tests for Arch Linux Installation Script Components
# Author: sqazi
# Version: 1.0.0
# Date: January 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Test script syntax
test_syntax() {
    print_header "Testing Script Syntax"
    
    if bash -n ../Install.sh; then
        print_status "Install.sh syntax is valid"
        return 0
    else
        print_fail "Install.sh has syntax errors"
        return 1
    fi
}

# Test function definitions
test_functions() {
    print_header "Testing Function Definitions"
    
    local script_path="../Install.sh"
    local required_functions=(
        "configure_installation"
        "check_prerequisites"
        "partition_disk"
        "format_partitions"
        "setup_zfs"
        "install_base_system"
        "configure_system"
        "apply_z13_fixes"
        "install_power_management"
        "install_desktop"
        "install_gaming"
        "configure_snapshots"
        "set_passwords"
        "final_update"
        "cleanup_and_finish"
    )
    
    local missing_functions=()
    
    for func in "${required_functions[@]}"; do
        if ! grep -q "^${func}()" "$script_path"; then
            missing_functions+=("$func")
        fi
    done
    
    if [[ ${#missing_functions[@]} -eq 0 ]]; then
        print_status "All required functions are defined"
        return 0
    else
        print_fail "Missing functions: ${missing_functions[*]}"
        return 1
    fi
}

# Test ZFS configuration
test_zfs_config() {
    print_header "Testing ZFS Configuration"
    
    local script_path="../Install.sh"
    local zfs_checks=(
        "zpool create"
        "zfs create"
        "compression=zstd"
        "auto-snapshot"
    )
    
    local missing_checks=()
    
    for check in "${zfs_checks[@]}"; do
        if ! grep -q "$check" "$script_path"; then
            missing_checks+=("$check")
        fi
    done
    
    if [[ ${#missing_checks[@]} -eq 0 ]]; then
        print_status "ZFS configuration is complete"
        return 0
    else
        print_fail "Missing ZFS configurations: ${missing_checks[*]}"
        return 1
    fi
}

# Test hardware fixes
test_hardware_fixes() {
    print_header "Testing Z13 Hardware Fixes"
    
    local script_path="../Install.sh"
    local hardware_fixes=(
        "mt7925e.*disable_aspm"
        "hid_asus"
        "i915.enable_psr=0"
        "reload-hid_asus.service"
    )
    
    local missing_fixes=()
    
    for fix in "${hardware_fixes[@]}"; do
        if ! grep -qE "$fix" "$script_path"; then
            missing_fixes+=("$fix")
        fi
    done
    
    if [[ ${#missing_fixes[@]} -eq 0 ]]; then
        print_status "All Z13 hardware fixes are present"
        return 0
    else
        print_fail "Missing hardware fixes: ${missing_fixes[*]}"
        return 1
    fi
}

# Test power management
test_power_management() {
    print_header "Testing Power Management"
    
    local script_path="../Install.sh"
    local power_tools=(
        "asusctl"
        "power-profiles-daemon"
        "tlp"
    )
    
    local missing_tools=()
    
    for tool in "${power_tools[@]}"; do
        if ! grep -q "$tool" "$script_path"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        print_status "Power management tools are configured"
        return 0
    else
        print_fail "Missing power management tools: ${missing_tools[*]}"
        return 1
    fi
}

# Test desktop environment support
test_desktop_environments() {
    print_header "Testing Desktop Environment Support"
    
    local script_path="../Install.sh"
    local desktop_envs=(
        "xfce"
        "omarchy"
        "i3"
        "gnome"
        "kde"
        "minimal"
    )
    
    local missing_envs=()
    
    for env in "${desktop_envs[@]}"; do
        if ! grep -q "\"$env\"" "$script_path"; then
            missing_envs+=("$env")
        fi
    done
    
    if [[ ${#missing_envs[@]} -eq 0 ]]; then
        print_status "All desktop environments are supported"
        return 0
    else
        print_fail "Missing desktop environments: ${missing_envs[*]}"
        return 1
    fi
}

# Test error handling
test_error_handling() {
    print_header "Testing Error Handling"
    
    local script_path="../Install.sh"
    local error_checks=(
        "set -e"
        "print_error"
        "exit 1"
    )
    
    local missing_checks=()
    
    for check in "${error_checks[@]}"; do
        if ! grep -q "$check" "$script_path"; then
            missing_checks+=("$check")
        fi
    done
    
    if [[ ${#missing_checks[@]} -eq 0 ]]; then
        print_status "Error handling is properly implemented"
        return 0
    else
        print_fail "Missing error handling: ${missing_checks[*]}"
        return 1
    fi
}

# Run all tests
run_all_tests() {
    print_header "Running Unit Tests for Arch Linux Installation"
    
    local tests=(
        "test_syntax"
        "test_functions"
        "test_zfs_config"
        "test_hardware_fixes"
        "test_power_management"
        "test_desktop_environments"
        "test_error_handling"
    )
    
    local passed=0
    local failed=0
    
    for test in "${tests[@]}"; do
        if $test; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    print_header "Test Results Summary"
    echo "Passed: $passed"
    echo "Failed: $failed"
    echo "Total: $((passed + failed))"
    
    if [[ $failed -eq 0 ]]; then
        print_status "All unit tests passed!"
        return 0
    else
        print_fail "$failed test(s) failed"
        return 1
    fi
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        run_all_tests
    else
        # Run specific test
        case "$1" in
            "syntax") test_syntax ;;
            "functions") test_functions ;;
            "zfs") test_zfs_config ;;
            "hardware") test_hardware_fixes ;;
            "power") test_power_management ;;
            "desktop") test_desktop_environments ;;
            "error") test_error_handling ;;
            *) echo "Usage: $0 [syntax|functions|zfs|hardware|power|desktop|error]" ;;
        esac
    fi
}

# Run main function
main "$@"
