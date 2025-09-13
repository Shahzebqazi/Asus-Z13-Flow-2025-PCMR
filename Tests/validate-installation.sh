#!/bin/bash
# Installation Validation Script for ASUS ROG Flow Z13 (2025)
# Tests critical installation components and hardware optimizations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test functions
test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    ((TESTS_TOTAL++))
    
    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}[PASS]${NC} $test_name: $message"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}[FAIL]${NC} $test_name: $message"
        ((TESTS_FAILED++))
    fi
}

test_warning() {
    local test_name="$1"
    local message="$2"
    echo -e "${YELLOW}[WARN]${NC} $test_name: $message"
}

test_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message"
}

# Hardware Detection Tests
test_hardware_detection() {
    test_info "Testing hardware detection..."
    
    # Test AMD CPU detection
    if lscpu | grep -qi "AMD"; then
        test_result "AMD CPU Detection" "PASS" "AMD processor detected"
        
        # Test for Strix Halo specifically
        if lscpu | grep -Eiq "strix.*halo|ryzen.*ai.*max|395"; then
            test_result "Strix Halo Detection" "PASS" "AMD Strix Halo detected"
        else
            test_result "Strix Halo Detection" "FAIL" "Strix Halo not detected (may be different AMD CPU)"
        fi
    else
        test_result "AMD CPU Detection" "FAIL" "AMD processor not detected"
    fi
    
    # Test AMD GPU detection
    if lspci | grep -Eiq "amd|radeon"; then
        test_result "AMD GPU Detection" "PASS" "AMD GPU detected"
    else
        test_result "AMD GPU Detection" "FAIL" "AMD GPU not detected"
    fi
    
    # Test WiFi adapter detection
    if lspci | grep -iq "mt7925e"; then
        test_result "MT7925e WiFi Detection" "PASS" "MediaTek MT7925e WiFi adapter detected"
    else
        test_result "MT7925e WiFi Detection" "FAIL" "MediaTek MT7925e not detected"
    fi
}

# Installation Script Tests
test_installation_scripts() {
    test_info "Testing installation script integrity..."
    
    # Test main script exists and is executable
    if [[ -f "Install_Arch.sh" && -x "Install_Arch.sh" ]]; then
        test_result "Main Script" "PASS" "Install_Arch.sh exists and is executable"
    else
        test_result "Main Script" "FAIL" "Install_Arch.sh missing or not executable"
    fi
    
    # Test Source script redirect
    if [[ -f "Source/Install_Arch.sh" ]]; then
        if grep -q "exec.*Install_Arch.sh" "Source/Install_Arch.sh"; then
            test_result "Source Script Redirect" "PASS" "Source script properly redirects to main script"
        else
            test_result "Source Script Redirect" "FAIL" "Source script does not redirect properly"
        fi
    else
        test_result "Source Script Redirect" "FAIL" "Source/Install_Arch.sh not found"
    fi
    
    # Test module availability
    local modules=("DiskManagement" "FilesystemSetup" "CoreInstallation" "Bootloader" "HardwareEnablement")
    for module in "${modules[@]}"; do
        if [[ -f "Modules/${module}.sh" ]]; then
            test_result "Module: $module" "PASS" "${module}.sh exists"
        else
            test_result "Module: $module" "FAIL" "${module}.sh missing"
        fi
    done
}

# Configuration Tests
test_configurations() {
    test_info "Testing configuration files..."
    
    # Test JSON configuration files
    local configs=("Zen.json" "DualBootZen.json")
    for config in "${configs[@]}"; do
        if [[ -f "Configs/$config" ]]; then
            if python3 -m json.tool "Configs/$config" >/dev/null 2>&1; then
                test_result "Config: $config" "PASS" "Valid JSON configuration"
            else
                test_result "Config: $config" "FAIL" "Invalid JSON syntax"
            fi
        else
            test_result "Config: $config" "FAIL" "Configuration file missing"
        fi
    done
}

# Function Dependency Tests
test_function_dependencies() {
    test_info "Testing function dependencies..."
    
    # Test for require_cmd function in Source modules
    if grep -q "require_cmd()" "Source/Modules/CoreInstallation.sh" 2>/dev/null; then
        test_result "Function Dependencies" "PASS" "require_cmd function defined in Source modules"
    else
        test_result "Function Dependencies" "FAIL" "require_cmd function missing in Source modules"
    fi
    
    # Test for HandleFatalError usage consistency
    local fatal_error_count=$(grep -r "HandleFatalError" Modules/ | wc -l)
    if [[ $fatal_error_count -gt 0 ]]; then
        test_result "Error Handling" "PASS" "HandleFatalError used in modules ($fatal_error_count instances)"
    else
        test_result "Error Handling" "FAIL" "No error handling found in modules"
    fi
}

# Hardware Optimization Tests
test_hardware_optimizations() {
    test_info "Testing hardware optimizations..."
    
    # Test for AMD GPU optimizations
    if grep -q "amdgpu.*ppfeaturemask" "Modules/HardwareEnablement.sh" 2>/dev/null; then
        test_result "AMD GPU Optimizations" "PASS" "AMD GPU optimizations present"
    else
        test_result "AMD GPU Optimizations" "FAIL" "AMD GPU optimizations missing"
    fi
    
    # Test for MT7925e WiFi fixes
    if grep -q "mt7925e.*disable_aspm" "Modules/HardwareEnablement.sh" 2>/dev/null; then
        test_result "WiFi Stability Fixes" "PASS" "MT7925e ASPM fixes present"
    else
        test_result "WiFi Stability Fixes" "FAIL" "MT7925e ASPM fixes missing"
    fi
    
    # Test for power management
    if grep -q "power_save=0" "Modules/HardwareEnablement.sh" 2>/dev/null; then
        test_result "Power Management" "PASS" "WiFi power management optimizations present"
    else
        test_result "Power Management" "FAIL" "WiFi power management optimizations missing"
    fi
}

# Security Tests
test_security() {
    test_info "Testing security practices..."
    
    # Test for password validation
    if grep -q "MIN_PASSWORD_LENGTH" "Install_Arch.sh" 2>/dev/null; then
        test_result "Password Validation" "PASS" "Password length validation present"
    else
        test_result "Password Validation" "FAIL" "Password length validation missing"
    fi
    
    # Test for input validation functions
    local validation_functions=("ValidateNumericInput" "ValidateChoice" "ValidateYesNo" "ValidateHostname" "ValidateUsername")
    local validation_count=0
    for func in "${validation_functions[@]}"; do
        if grep -q "$func" "Install_Arch.sh" 2>/dev/null; then
            ((validation_count++))
        fi
    done
    
    if [[ $validation_count -eq ${#validation_functions[@]} ]]; then
        test_result "Input Validation" "PASS" "All validation functions present"
    else
        test_result "Input Validation" "FAIL" "Missing validation functions ($validation_count/${#validation_functions[@]})"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}PCMR Arch Installer Validation${NC}"
    echo -e "${BLUE}ASUS ROG Flow Z13 (2025)${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # Change to script directory
    cd "$(dirname "${BASH_SOURCE[0]}")/.."
    
    # Run all tests
    test_hardware_detection
    echo
    test_installation_scripts
    echo
    test_configurations
    echo
    test_function_dependencies
    echo
    test_hardware_optimizations
    echo
    test_security
    echo
    
    # Summary
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "Total Tests: $TESTS_TOTAL"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! Installation system is ready.${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed. Please review and fix issues before deployment.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
