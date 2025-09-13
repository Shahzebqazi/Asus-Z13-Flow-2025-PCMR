# PCMR Arch Installer Test Suite

Comprehensive testing framework for the ASUS ROG Flow Z13 Arch Linux installer and Windows preparation scripts.

## 📁 **Directory Structure**

```
Tests/
├── PowerShell/           # Windows PowerShell script tests
│   ├── Unit/            # Unit tests for individual functions
│   ├── Integration/     # Integration tests for script workflows
│   ├── E2E/            # End-to-end tests for complete scenarios
│   ├── Fixtures/       # Test data and mock files
│   └── Mocks/          # Mock objects and stubs
├── ArchLinux/          # Arch Linux installation script tests
│   ├── Unit/           # Unit tests for bash functions
│   ├── Integration/    # Integration tests for module interactions
│   ├── E2E/           # End-to-end installation tests
│   ├── Fixtures/      # Test configurations and mock data
│   └── Mocks/         # Mock system commands and responses
├── Common/            # Shared testing utilities
├── Reports/           # Test execution reports and coverage
└── Scripts/           # Test runner and automation scripts
```

## 🧪 **Test Categories**

### **Unit Tests**
- Test individual functions in isolation
- Mock external dependencies
- Fast execution, high coverage

### **Integration Tests**
- Test module interactions
- Verify data flow between components
- Test configuration parsing and validation

### **End-to-End Tests**
- Test complete installation workflows
- Use virtual machines or containers
- Verify final system state

## 🚀 **Running Tests**

### **PowerShell Tests**
```powershell
# Run all PowerShell tests
.\Tests\Scripts\Run-PowerShellTests.ps1

# Run specific test category
.\Tests\Scripts\Run-PowerShellTests.ps1 -Category Unit

# Run with coverage report
.\Tests\Scripts\Run-PowerShellTests.ps1 -Coverage
```

### **Arch Linux Tests**
```bash
# Run all Arch Linux tests
./Tests/Scripts/run-arch-tests.sh

# Run specific test category
./Tests/Scripts/run-arch-tests.sh --category unit

# Run with coverage report
./Tests/Scripts/run-arch-tests.sh --coverage
```

### **Full Test Suite**
```bash
# Run complete test suite
./Tests/Scripts/run-all-tests.sh

# Generate comprehensive report
./Tests/Scripts/run-all-tests.sh --report
```

## 🛠️ **Test Development**

### **PowerShell Test Example**
```powershell
# Tests/PowerShell/Unit/Test-PreinstallCheck.ps1
Describe "Preinstall-Check Tests" {
    Context "System Requirements" {
        It "Should detect UEFI boot mode" {
            Mock Get-WmiObject { @{ Name = "UEFI" } }
            Test-UEFIMode | Should -Be $true
        }
        
        It "Should validate disk space" {
            Mock Get-WmiObject { @{ Size = 500GB } }
            Test-DiskSpace -RequiredGB 100 | Should -Be $true
        }
    }
}
```

### **Bash Test Example**
```bash
# Tests/ArchLinux/Unit/test-disk-management.sh
#!/usr/bin/env bats

@test "should detect EFI partition correctly" {
    # Mock lsblk output
    function lsblk() { echo "nvme0n1p1 c12a7328-f81f-11d2-ba4b-00a0c93ec93b"; }
    export -f lsblk
    
    source Modules/DiskManagement.sh
    result=$(detect_efi_partition "/dev/nvme0n1")
    [ "$result" = "/dev/nvme0n1p1" ]
}
```

## 📊 **Test Coverage Goals**

- **PowerShell Scripts**: >90% function coverage
- **Arch Linux Scripts**: >85% function coverage
- **Integration Tests**: All major workflows covered
- **E2E Tests**: Complete installation scenarios

## 🔧 **Testing Tools**

### **PowerShell**
- **Pester**: PowerShell testing framework
- **PSScriptAnalyzer**: Code quality analysis
- **PowerShell Coverage**: Code coverage reporting

### **Bash/Linux**
- **BATS**: Bash Automated Testing System
- **ShellCheck**: Shell script analysis
- **kcov**: Code coverage for shell scripts

## 📝 **Contributing Tests**

1. **Write tests first** (TDD approach)
2. **Follow naming conventions**: `Test-FunctionName.ps1` or `test-function-name.sh`
3. **Include both positive and negative test cases**
4. **Mock external dependencies**
5. **Document test purpose and expected behavior**

## 🚨 **Continuous Integration**

Tests are automatically run on:
- Pull requests to `stable` branch
- Commits to `development` branch
- Scheduled nightly runs

## 📈 **Test Reports**

Test results and coverage reports are generated in:
- `Tests/Reports/PowerShell/`
- `Tests/Reports/ArchLinux/`
- `Tests/Reports/Combined/`

Reports include:
- Test execution results
- Code coverage metrics
- Performance benchmarks
- Failure analysis
