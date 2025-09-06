#!/bin/bash

# unit_tests.sh - Individual unit tests for installation script components
# Author: sqazi with Claude-4-Sonnet
# Version: 1.0.0

set -euo pipefail

# Test configuration
SCRIPT_PATH="../my_arch_install.sh"
TEST_RESULTS_DIR="./test_results"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test() { echo -e "${BLUE}[TEST]${NC} $1"; }
print_pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
print_fail() { echo -e "${RED}[FAIL]${NC} $1"; }

# Unit Test: ZFS Configuration
test_zfs_configuration() {
    print_test "Testing ZFS configuration..."
    
    local errors=0
    
    # Check for ZFS pool creation
    if ! grep -q "zpool create" "$SCRIPT_PATH"; then
        print_fail "ZFS pool creation not found"
        ((errors++))
    fi
    
    # Check for ZFS datasets
    if ! grep -q "zfs create.*zroot/ROOT" "$SCRIPT_PATH"; then
        print_fail "ZFS ROOT dataset creation not found"
        ((errors++))
    fi
    
    # Check for ZFS compression
    if ! grep -q "compression=zstd" "$SCRIPT_PATH"; then
        print_fail "ZFS compression not configured"
        ((errors++))
    fi
    
    # Check for ZFS snapshots
    if ! grep -q "auto-snapshot" "$SCRIPT_PATH"; then
        print_fail "ZFS auto-snapshot not configured"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_pass "ZFS configuration test passed"
        return 0
    else
        print_fail "ZFS configuration test failed ($errors errors)"
        return 1
    fi
}

# Unit Test: XFCE Desktop Environment
test_xfce_desktop() {
    print_test "Testing XFCE desktop environment..."
    
    local errors=0
    local required_packages=("xfce4" "xfce4-goodies" "lightdm" "lightdm-gtk-greeter")
    
    for package in "${required_packages[@]}"; do
        if ! grep -q "$package" "$SCRIPT_PATH"; then
            print_fail "Required XFCE package not found: $package"
            ((errors++))
        fi
    done
    
    # Check for audio support
    if ! grep -q "pulseaudio" "$SCRIPT_PATH"; then
        print_fail "Audio support (PulseAudio) not configured"
        ((errors++))
    fi
    
    # Check for network manager applet
    if ! grep -q "network-manager-applet" "$SCRIPT_PATH"; then
        print_fail "Network manager applet not included"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_pass "XFCE desktop test passed"
        return 0
    else
        print_fail "XFCE desktop test failed ($errors errors)"
        return 1
    fi
}

# Unit Test: Power Management
test_power_management() {
    print_test "Testing power management configuration..."
    
    local errors=0
    
    # Check for asusctl (AUR package)
    if ! grep -q "yay.*asusctl" "$SCRIPT_PATH"; then
        print_fail "asusctl installation via AUR not found"
        ((errors++))
    fi
    
    # Check for TLP
    if ! grep -q "tlp" "$SCRIPT_PATH"; then
        print_fail "TLP power management not found"
        ((errors++))
    fi
    
    # Check for power-profiles-daemon
    if ! grep -q "power-profiles-daemon" "$SCRIPT_PATH"; then
        print_fail "power-profiles-daemon not found"
        ((errors++))
    fi
    
    # Check for TDP configuration
    if ! grep -q "7W\|54W" "$SCRIPT_PATH"; then
        print_fail "TDP configuration references not found"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_pass "Power management test passed"
        return 0
    else
        print_fail "Power management test failed ($errors errors)"
        return 1
    fi
}

# Unit Test: Z13 Hardware Fixes
test_z13_hardware_fixes() {
    print_test "Testing Z13-specific hardware fixes..."
    
    local errors=0
    local fixes=(
        "mt7925e.*disable_aspm=1"
        "hid_asus"
        "i915.enable_psr=0"
        "reload-hid_asus.service"
    )
    
    for fix in "${fixes[@]}"; do
        if ! grep -q "$fix" "$SCRIPT_PATH"; then
            print_fail "Z13 fix not found: $fix"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        print_pass "Z13 hardware fixes test passed"
        return 0
    else
        print_fail "Z13 hardware fixes test failed ($errors errors)"
        return 1
    fi
}

# Unit Test: Gaming Setup
test_gaming_setup() {
    print_test "Testing gaming configuration..."
    
    local errors=0
    
    # Check for multilib repository
    if ! grep -q "multilib" "$SCRIPT_PATH"; then
        print_fail "Multilib repository not enabled"
        ((errors++))
    fi
    
    # Check for Steam
    if ! grep -q "steam" "$SCRIPT_PATH"; then
        print_fail "Steam installation not found"
        ((errors++))
    fi
    
    # Check for gaming tools
    local gaming_tools=("gamemode" "mangohud")
    for tool in "${gaming_tools[@]}"; do
        if ! grep -q "$tool" "$SCRIPT_PATH"; then
            print_fail "Gaming tool not found: $tool"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        print_pass "Gaming setup test passed"
        return 0
    else
        print_fail "Gaming setup test failed ($errors errors)"
        return 1
    fi
}

# Unit Test: Error Handling
test_error_handling() {
    print_test "Testing error handling..."
    
    local errors=0
    
    # Check for set -e
    if ! grep -q "set -e" "$SCRIPT_PATH"; then
        print_fail "Error handling (set -e) not found"
        ((errors++))
    fi
    
    # Check for error messages
    if ! grep -q "print_error" "$SCRIPT_PATH"; then
        print_fail "Error message function not found"
        ((errors++))
    fi
    
    # Check for exit on error
    if ! grep -q "exit 1" "$SCRIPT_PATH"; then
        print_fail "Error exit conditions not found"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_pass "Error handling test passed"
        return 0
    else
        print_fail "Error handling test failed ($errors errors)"
        return 1
    fi
}

# Run all unit tests
run_all_tests() {
    echo "🧪 Running Unit Tests for Arch Linux Installation Script"
    echo "======================================================="
    
    mkdir -p "$TEST_RESULTS_DIR"
    
    local total_tests=0
    local passed_tests=0
    
    # Array of test functions
    local tests=(
        "test_zfs_configuration"
        "test_xfce_desktop"
        "test_power_management"
        "test_z13_hardware_fixes"
        "test_gaming_setup"
        "test_error_handling"
    )
    
    # Run each test
    for test_func in "${tests[@]}"; do
        ((total_tests++))
        if $test_func; then
            ((passed_tests++))
        fi
        echo ""
    done
    
    # Generate summary
    echo "📊 Test Summary"
    echo "==============="
    echo "Total Tests: $total_tests"
    echo "Passed: $passed_tests"
    echo "Failed: $((total_tests - passed_tests))"
    
    if [[ $passed_tests -eq $total_tests ]]; then
        print_pass "All unit tests passed! ✨"
        return 0
    else
        print_fail "Some unit tests failed. Review output above."
        return 1
    fi
}

# Main execution
main() {
    if [[ ! -f "$SCRIPT_PATH" ]]; then
        print_fail "Installation script not found: $SCRIPT_PATH"
        exit 1
    fi
    
    run_all_tests
}

main "$@"
