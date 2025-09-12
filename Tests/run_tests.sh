#!/bin/bash
# Test Runner for Z13 Installation Script
# Provides various testing modes and continuous integration support

set -e

# Configuration
SCRIPT_DIR="$(dirname "$(dirname "$0")")"
TEST_DIR="$(dirname "$0")"
RESULTS_DIR="$TEST_DIR/results"
COVERAGE_DIR="$TEST_DIR/coverage"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test modes
MODE_UNIT="unit"
MODE_INTEGRATION="integration"
MODE_PERFORMANCE="performance"
MODE_SECURITY="security"
MODE_ALL="all"
MODE_CI="ci"

print_usage() {
    cat << EOF
Z13 Installation Script Test Runner

USAGE:
    $0 [MODE] [OPTIONS]

MODES:
    unit            Run unit tests only
    integration     Run integration tests only
    performance     Run performance tests only
    security        Run security tests only
    all             Run all tests (default)
    ci              Run tests in CI mode with coverage

OPTIONS:
    --verbose       Enable verbose output
    --coverage      Generate code coverage report
    --html-report   Generate HTML test report
    --junit-xml     Generate JUnit XML report
    --help, -h      Show this help message

EXAMPLES:
    $0 unit --verbose
    $0 all --coverage --html-report
    $0 ci
    $0 security

EOF
}

setup_test_environment() {
    echo -e "${BLUE}Setting up test environment...${NC}"
    
    # Create necessary directories
    mkdir -p "$RESULTS_DIR" "$COVERAGE_DIR"
    
    # Install test dependencies if needed
    if ! command -v bc >/dev/null 2>&1; then
        echo "Installing bc for test calculations..."
        # Note: In actual environment, this would install bc
    fi
    
    # Set up mock environment
    export TEST_MODE=true
    export MOCK_COMMANDS=true
    
    echo -e "${GREEN}Test environment ready${NC}"
}

run_unit_tests() {
    echo -e "${BLUE}Running Unit Tests...${NC}"
    
    local test_script="$TEST_DIR/test_framework.sh"
    local results_file="$RESULTS_DIR/unit_tests.log"
    
    if [[ -f "$test_script" ]]; then
        # Run specific test functions
        bash "$test_script" unit 2>&1 | tee "$results_file"
        return ${PIPESTATUS[0]}
    else
        echo -e "${RED}Unit test script not found: $test_script${NC}"
        return 1
    fi
}

run_integration_tests() {
    echo -e "${BLUE}Running Integration Tests...${NC}"
    
    local results_file="$RESULTS_DIR/integration_tests.log"
    
    # Test module loading and interaction
    {
        echo "=== Integration Test Suite ==="
        echo "Testing module interdependencies..."
        
        # Test configuration loading chain
        echo "Testing configuration loading..."
        if source "$SCRIPT_DIR/pcmr.sh" 2>/dev/null; then
            echo "PASS: Main script loads successfully"
        else
            echo "FAIL: Main script failed to load"
        fi
        
        # Test module dependencies
        local modules=("DiskManagement" "FilesystemSetup" "CoreInstallation" "SystemConfiguration")
        for module in "${modules[@]}"; do
            local module_file="$SCRIPT_DIR/Modules/${module}.sh"
            if [[ -f "$module_file" ]]; then
                if bash -n "$module_file"; then
                    echo "PASS: $module syntax check"
                else
                    echo "FAIL: $module syntax errors"
                fi
            else
                echo "FAIL: $module file not found"
            fi
        done
        
        # Test configuration files
        local configs=(
            "Zen.json"
            "Level1Techs.json"
            "QuickStart.json"
            "FreshZen.json"
            "FreshStandard.json"
            "DualBootZen.json"
            "DualBootStandard.json"
        )
        for config in "${configs[@]}"; do
            local config_file="$SCRIPT_DIR/Configs/${config}"
            if [[ -f "$config_file" ]]; then
                if python3 -m json.tool "$config_file" >/dev/null 2>&1; then
                    echo "PASS: $config JSON validation"
                else
                    echo "FAIL: $config invalid JSON"
                fi
            else
                echo "FAIL: $config file not found"
            fi
        done
        
    } 2>&1 | tee "$results_file"
    
    # Check for any failures
    if grep -q "FAIL:" "$results_file"; then
        return 1
    else
        return 0
    fi
}

run_performance_tests() {
    echo -e "${BLUE}Running Performance Tests...${NC}"
    
    local results_file="$RESULTS_DIR/performance_tests.log"
    
    {
        echo "=== Performance Test Suite ==="
        
        # Test script startup time
        echo "Testing script startup performance..."
        local start_time=$(date +%s.%N)
        source "$SCRIPT_DIR/pcmr.sh" >/dev/null 2>&1 || true
        local end_time=$(date +%s.%N)
        local startup_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "1.0")
        
        if (( $(echo "$startup_time < 2.0" | bc -l 2>/dev/null || echo 0) )); then
            echo "PASS: Script startup time: ${startup_time}s"
        else
            echo "FAIL: Script startup time too slow: ${startup_time}s"
        fi
        
        # Test validation function performance
        echo "Testing validation function performance..."
        local validation_start=$(date +%s.%N)
        for i in {1..1000}; do
            echo "test-hostname-$i" | grep -q "^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$" || true
        done
        local validation_end=$(date +%s.%N)
        local validation_time=$(echo "$validation_end - $validation_start" | bc 2>/dev/null || echo "1.0")
        
        if (( $(echo "$validation_time < 1.0" | bc -l 2>/dev/null || echo 0) )); then
            echo "PASS: Validation performance: ${validation_time}s for 1000 operations"
        else
            echo "FAIL: Validation performance too slow: ${validation_time}s"
        fi
        
        # Test memory usage
        echo "Testing memory usage..."
        local memory_start=$(ps -o pid,vsz,rss -p $$ | tail -1 | awk '{print $2}')
        
        # Simulate some operations
        for i in {1..100}; do
            local dummy_array[$i]="test-data-$i"
        done
        
        local memory_end=$(ps -o pid,vsz,rss -p $$ | tail -1 | awk '{print $2}')
        local memory_diff=$((memory_end - memory_start))
        
        if [[ $memory_diff -lt 50000 ]]; then  # Less than 50MB
            echo "PASS: Memory usage acceptable: ${memory_diff}KB"
        else
            echo "FAIL: High memory usage: ${memory_diff}KB"
        fi
        
    } 2>&1 | tee "$results_file"
    
    # Check for failures
    if grep -q "FAIL:" "$results_file"; then
        return 1
    else
        return 0
    fi
}

run_security_tests() {
    echo -e "${BLUE}Running Security Tests...${NC}"
    
    local results_file="$RESULTS_DIR/security_tests.log"
    
    {
        echo "=== Security Test Suite ==="
        
        # Test for potential security issues in scripts
        echo "Scanning for security vulnerabilities..."
        
        # Check for unsafe variable expansions
        local unsafe_patterns=('$(' '`' 'eval' 'exec')
        local security_issues=0
        
        for pattern in "${unsafe_patterns[@]}"; do
            local matches=$(grep -r "$pattern" "$SCRIPT_DIR" --include="*.sh" | wc -l)
            if [[ $matches -gt 0 ]]; then
                echo "WARNING: Found $matches instances of potentially unsafe pattern: $pattern"
                ((security_issues++))
            fi
        done
        
        # Check for hardcoded credentials
        local credential_patterns=('password=' 'passwd=' 'secret=' 'key=' 'token=')
        for pattern in "${credential_patterns[@]}"; do
            local matches=$(grep -ri "$pattern" "$SCRIPT_DIR" --include="*.sh" --include="*.json" | grep -v "test" | wc -l)
            if [[ $matches -gt 0 ]]; then
                echo "FAIL: Found potential hardcoded credentials: $pattern"
                ((security_issues++))
            fi
        done
        
        # Check file permissions
        echo "Checking file permissions..."
        local executable_files=$(find "$SCRIPT_DIR" -name "*.sh" -type f)
        for file in $executable_files; do
            local perms=$(stat -f "%Mp%Lp" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null || echo "000")
            if [[ "$perms" =~ ^[67][0-4][0-4]$ ]]; then
                echo "PASS: $file has secure permissions ($perms)"
            else
                echo "WARNING: $file has potentially insecure permissions ($perms)"
            fi
        done
        
        # Test input validation
        echo "Testing input validation security..."
        source "$SCRIPT_DIR/pcmr.sh" 2>/dev/null || true
        
        # Test malicious inputs
        local malicious_inputs=(
            "../../../etc/passwd"
            "'; rm -rf /; echo '"
            "\$(whoami)"
            "\`id\`"
            "root; cat /etc/shadow"
        )
        
        for input in "${malicious_inputs[@]}"; do
            if ! ValidateHostname "$input" 2>/dev/null; then
                echo "PASS: Blocked malicious input in hostname: $input"
            else
                echo "FAIL: Malicious input not blocked in hostname: $input"
                ((security_issues++))
            fi
        done
        
        # Summary
        if [[ $security_issues -eq 0 ]]; then
            echo "PASS: No critical security issues found"
        else
            echo "FAIL: Found $security_issues potential security issues"
        fi
        
    } 2>&1 | tee "$results_file"
    
    # Check for failures
    if grep -q "FAIL:" "$results_file"; then
        return 1
    else
        return 0
    fi
}

generate_coverage_report() {
    echo -e "${BLUE}Generating code coverage report...${NC}"
    
    # Simple coverage analysis based on function calls
    local coverage_file="$COVERAGE_DIR/coverage.txt"
    
    {
        echo "=== Code Coverage Report ==="
        echo "Generated: $(date)"
        echo ""
        
        # Extract function definitions
        local total_functions=$(grep -r "^[a-zA-Z_][a-zA-Z0-9_]*() {" "$SCRIPT_DIR" --include="*.sh" | wc -l)
        echo "Total functions found: $total_functions"
        
        # This is a simplified coverage analysis
        # In a real scenario, you'd use tools like bashcov or kcov
        echo "Note: This is a simplified coverage report."
        echo "For detailed coverage, use specialized tools like bashcov or kcov."
        
    } > "$coverage_file"
    
    echo "Coverage report generated: $coverage_file"
}

generate_html_report() {
    echo -e "${BLUE}Generating HTML test report...${NC}"
    
    local html_file="$RESULTS_DIR/test_report.html"
    
    cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Z13 Installation Script Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .pass { color: green; }
        .fail { color: red; }
        .warning { color: orange; }
        .test-section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        pre { background-color: #f8f8f8; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Z13 Installation Script Test Report</h1>
        <p>Generated: <script>document.write(new Date().toLocaleString());</script></p>
    </div>
EOF
    
    # Add test results
    for result_file in "$RESULTS_DIR"/*.log; do
        if [[ -f "$result_file" ]]; then
            local test_name=$(basename "$result_file" .log)
            echo "<div class=\"test-section\">" >> "$html_file"
            echo "<h2>$test_name</h2>" >> "$html_file"
            echo "<pre>" >> "$html_file"
            sed 's/PASS:/<span class="pass">PASS:<\/span>/g; s/FAIL:/<span class="fail">FAIL:<\/span>/g; s/WARNING:/<span class="warning">WARNING:<\/span>/g' "$result_file" >> "$html_file"
            echo "</pre>" >> "$html_file"
            echo "</div>" >> "$html_file"
        fi
    done
    
    echo "</body></html>" >> "$html_file"
    
    echo "HTML report generated: $html_file"
}

generate_junit_xml() {
    echo -e "${BLUE}Generating JUnit XML report...${NC}"
    
    local xml_file="$RESULTS_DIR/junit.xml"
    
    cat > "$xml_file" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="Z13InstallationScriptTests" tests="0" failures="0" errors="0" time="0">
EOF
    
    # Process test results and convert to JUnit format
    # This is a simplified implementation
    local test_count=0
    local failure_count=0
    
    for result_file in "$RESULTS_DIR"/*.log; do
        if [[ -f "$result_file" ]]; then
            local passes=$(grep -c "PASS:" "$result_file" 2>/dev/null || echo "0")
            local failures=$(grep -c "FAIL:" "$result_file" 2>/dev/null || echo "0")
            
            test_count=$((test_count + passes + failures))
            failure_count=$((failure_count + failures))
        fi
    done
    
    # Update test suite attributes
    sed -i.bak "s/tests=\"0\"/tests=\"$test_count\"/" "$xml_file"
    sed -i.bak "s/failures=\"0\"/failures=\"$failure_count\"/" "$xml_file"
    rm -f "$xml_file.bak"
    
    echo "</testsuite>" >> "$xml_file"
    
    echo "JUnit XML report generated: $xml_file"
}

run_ci_mode() {
    echo -e "${BLUE}Running in CI mode...${NC}"
    
    # Set CI-specific options
    export CI_MODE=true
    export VERBOSE=false
    
    local exit_code=0
    
    # Run all test types
    run_unit_tests || exit_code=1
    run_integration_tests || exit_code=1
    run_performance_tests || exit_code=1
    run_security_tests || exit_code=1
    
    # Generate reports
    generate_coverage_report
    generate_html_report
    generate_junit_xml
    
    # Print summary
    echo ""
    echo -e "${BLUE}=== CI Test Summary ===${NC}"
    
    local total_tests=0
    local total_failures=0
    
    for result_file in "$RESULTS_DIR"/*.log; do
        if [[ -f "$result_file" ]]; then
            local passes=$(grep -c "PASS:" "$result_file" 2>/dev/null || echo "0")
            local failures=$(grep -c "FAIL:" "$result_file" 2>/dev/null || echo "0")
            
            total_tests=$((total_tests + passes + failures))
            total_failures=$((total_failures + failures))
            
            echo "$(basename "$result_file" .log): $passes passed, $failures failed"
        fi
    done
    
    echo ""
    echo "Total: $total_tests tests, $total_failures failures"
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
    else
        echo -e "${RED}❌ Some tests failed.${NC}"
    fi
    
    return $exit_code
}

main() {
    local mode="$MODE_ALL"
    local verbose=false
    local coverage=false
    local html_report=false
    local junit_xml=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            unit|integration|performance|security|all|ci)
                mode="$1"
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --coverage)
                coverage=true
                shift
                ;;
            --html-report)
                html_report=true
                shift
                ;;
            --junit-xml)
                junit_xml=true
                shift
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Set verbose mode
    if [[ "$verbose" == true ]]; then
        set -x
    fi
    
    echo "Z13 Installation Script Test Runner"
    echo "Mode: $mode"
    echo "Started: $(date)"
    echo ""
    
    setup_test_environment
    
    local exit_code=0
    
    case "$mode" in
        "$MODE_UNIT")
            run_unit_tests || exit_code=1
            ;;
        "$MODE_INTEGRATION")
            run_integration_tests || exit_code=1
            ;;
        "$MODE_PERFORMANCE")
            run_performance_tests || exit_code=1
            ;;
        "$MODE_SECURITY")
            run_security_tests || exit_code=1
            ;;
        "$MODE_CI")
            run_ci_mode || exit_code=1
            ;;
        "$MODE_ALL"|*)
            run_unit_tests || exit_code=1
            run_integration_tests || exit_code=1
            run_performance_tests || exit_code=1
            run_security_tests || exit_code=1
            ;;
    esac
    
    # Generate optional reports
    if [[ "$coverage" == true ]]; then
        generate_coverage_report
    fi
    
    if [[ "$html_report" == true ]]; then
        generate_html_report
    fi
    
    if [[ "$junit_xml" == true ]]; then
        generate_junit_xml
    fi
    
    echo ""
    echo "Test run completed: $(date)"
    echo "Results directory: $RESULTS_DIR"
    
    exit $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
