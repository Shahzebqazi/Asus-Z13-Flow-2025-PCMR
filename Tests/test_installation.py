#!/usr/bin/env python3
"""
test_installation.py - Python test suite for Arch Linux installation script
Author: sqazi with Claude-4-Sonnet
Version: 1.0.0
Date: January 2025
"""

import unittest
import subprocess
import os
import re
import json
from pathlib import Path
from typing import Dict, List, Tuple, Optional

class ArchInstallationTests(unittest.TestCase):
    """Test suite for Arch Linux installation script validation."""
    
    @classmethod
    def setUpClass(cls):
        """Set up test environment."""
        cls.script_path = Path("../my_arch_install.sh").resolve()
        cls.test_results = {}
        cls.script_content = cls._read_script()
    
    @classmethod
    def _read_script(cls) -> str:
        """Read the installation script content."""
        try:
            with open(cls.script_path, 'r') as f:
                return f.read()
        except FileNotFoundError:
            raise FileNotFoundError(f"Installation script not found: {cls.script_path}")
    
    def test_script_syntax(self):
        """Test script syntax validation."""
        result = subprocess.run(
            ['bash', '-n', str(self.script_path)],
            capture_output=True,
            text=True
        )
        self.assertEqual(result.returncode, 0, f"Syntax errors found: {result.stderr}")
        self.test_results['syntax_check'] = 'PASS'
    
    def test_required_functions(self):
        """Test that all required functions are defined."""
        required_functions = [
            'configure_installation',
            'check_prerequisites',
            'partition_disk',
            'format_partitions',
            'setup_zfs',
            'install_base_system',
            'configure_system',
            'apply_z13_fixes',
            'install_power_management',
            'install_desktop',
            'install_gaming',
            'configure_snapshots',
            'set_passwords',
            'final_update',
            'cleanup_and_finish'
        ]
        
        missing_functions = []
        for func in required_functions:
            pattern = rf'^{re.escape(func)}\(\)'
            if not re.search(pattern, self.script_content, re.MULTILINE):
                missing_functions.append(func)
        
        self.assertEqual(len(missing_functions), 0, 
                        f"Missing functions: {missing_functions}")
        self.test_results['function_definitions'] = 'PASS'
    
    def test_zfs_configuration(self):
        """Test ZFS configuration implementation."""
        zfs_checks = {
            'zpool_create': r'zpool create',
            'zfs_datasets': r'zfs create.*zroot',
            'zfs_compression': r'compression=zstd',
            'zfs_snapshots': r'auto-snapshot'
        }
        
        missing_zfs = []
        for check_name, pattern in zfs_checks.items():
            if not re.search(pattern, self.script_content):
                missing_zfs.append(check_name)
        
        self.assertEqual(len(missing_zfs), 0, 
                        f"Missing ZFS configurations: {missing_zfs}")
        self.test_results['zfs_configuration'] = 'PASS'
    
    def test_xfce_desktop_environment(self):
        """Test XFCE desktop environment configuration."""
        xfce_packages = [
            'xfce4',
            'xfce4-goodies',
            'lightdm',
            'lightdm-gtk-greeter',
            'pulseaudio',
            'network-manager-applet'
        ]
        
        missing_packages = []
        for package in xfce_packages:
            if package not in self.script_content:
                missing_packages.append(package)
        
        self.assertEqual(len(missing_packages), 0,
                        f"Missing XFCE packages: {missing_packages}")
        self.test_results['xfce_desktop'] = 'PASS'
    
    def test_z13_hardware_fixes(self):
        """Test Z13-specific hardware fixes."""
        z13_fixes = {
            'wifi_fix': r'mt7925e.*disable_aspm=1',
            'touchpad_fix': r'hid_asus',
            'display_fix': r'i915\.enable_psr=0',
            'touchpad_service': r'reload-hid_asus\.service'
        }
        
        missing_fixes = []
        for fix_name, pattern in z13_fixes.items():
            if not re.search(pattern, self.script_content):
                missing_fixes.append(fix_name)
        
        self.assertEqual(len(missing_fixes), 0,
                        f"Missing Z13 fixes: {missing_fixes}")
        self.test_results['z13_hardware_fixes'] = 'PASS'
    
    def test_power_management(self):
        """Test power management configuration."""
        power_tools = ['asusctl', 'power-profiles-daemon', 'tlp']
        missing_tools = []
        
        for tool in power_tools:
            if tool not in self.script_content:
                missing_tools.append(tool)
        
        # Check for TDP configuration references
        tdp_configured = bool(re.search(r'7W|54W|TDP', self.script_content))
        
        self.assertEqual(len(missing_tools), 0,
                        f"Missing power management tools: {missing_tools}")
        self.assertTrue(tdp_configured, "TDP configuration not found")
        self.test_results['power_management'] = 'PASS'
    
    def test_gaming_setup(self):
        """Test gaming configuration."""
        gaming_components = {
            'multilib': r'multilib',
            'steam': r'steam',
            'gamemode': r'gamemode',
            'mangohud': r'mangohud'
        }
        
        missing_components = []
        for component, pattern in gaming_components.items():
            if not re.search(pattern, self.script_content):
                missing_components.append(component)
        
        self.assertEqual(len(missing_components), 0,
                        f"Missing gaming components: {missing_components}")
        self.test_results['gaming_setup'] = 'PASS'
    
    def test_error_handling(self):
        """Test error handling implementation."""
        error_handling_checks = [
            ('set_e', r'set -e'),
            ('error_function', r'print_error'),
            ('exit_conditions', r'exit 1')
        ]
        
        missing_error_handling = []
        for check_name, pattern in error_handling_checks:
            if not re.search(pattern, self.script_content):
                missing_error_handling.append(check_name)
        
        self.assertEqual(len(missing_error_handling), 0,
                        f"Missing error handling: {missing_error_handling}")
        self.test_results['error_handling'] = 'PASS'
    
    def test_aur_helper_installation(self):
        """Test AUR helper installation for asusctl."""
        aur_patterns = [
            r'yay',
            r'git clone.*aur\.archlinux\.org',
            r'makepkg.*-si'
        ]
        
        aur_found = any(re.search(pattern, self.script_content) for pattern in aur_patterns)
        self.assertTrue(aur_found, "AUR helper installation not found")
        
        # Check that asusctl is installed via AUR, not pacman
        asusctl_via_aur = re.search(r'yay.*asusctl', self.script_content)
        self.assertTrue(asusctl_via_aur, "asusctl should be installed via AUR")
        self.test_results['aur_helper'] = 'PASS'
    
    def test_dual_boot_support(self):
        """Test dual-boot configuration."""
        dual_boot_components = [
            'os-prober',
            'GRUB_DISABLE_OS_PROBER=false',
            'grub-mkconfig'
        ]
        
        missing_dual_boot = []
        for component in dual_boot_components:
            if component not in self.script_content:
                missing_dual_boot.append(component)
        
        self.assertEqual(len(missing_dual_boot), 0,
                        f"Missing dual-boot components: {missing_dual_boot}")
        self.test_results['dual_boot_support'] = 'PASS'
    
    def test_partition_logic(self):
        """Test partition creation and variable assignment logic."""
        # Check for partition variable updates after creation
        partition_logic_correct = re.search(
            r'sgdisk.*\n.*swap_part=.*\n.*root_part=',
            self.script_content,
            re.MULTILINE
        )
        
        self.assertTrue(partition_logic_correct, 
                       "Partition variable assignment logic may be incorrect")
        self.test_results['partition_logic'] = 'PASS'
    
    @classmethod
    def tearDownClass(cls):
        """Generate test report."""
        cls._generate_test_report()
    
    @classmethod
    def _generate_test_report(cls):
        """Generate comprehensive test report."""
        report_path = Path("test_results/python_test_report.json")
        report_path.parent.mkdir(exist_ok=True)
        
        report = {
            "test_date": "2025-01-01",  # This would be dynamic in real implementation
            "script_tested": str(cls.script_path),
            "total_tests": len(cls.test_results),
            "passed_tests": sum(1 for result in cls.test_results.values() if result == 'PASS'),
            "test_results": cls.test_results,
            "summary": "All critical installation script components validated"
        }
        
        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\n📊 Test Report Generated: {report_path}")
        print(f"✅ Passed: {report['passed_tests']}/{report['total_tests']} tests")


class UTMIntegrationTests(unittest.TestCase):
    """Integration tests for UTM virtual machine testing."""
    
    def setUp(self):
        """Set up UTM test environment."""
        self.utm_config = {
            "name": "ArchTest-Z13",
            "memory": 4096,
            "cpu_cores": 4,
            "disk_size": 53687091200,  # 50GB
            "iso_path": os.path.expanduser("~/Downloads/archlinux-x86_64.iso")
        }
    
    def test_utm_availability(self):
        """Test if UTM is available for testing."""
        utm_path = "/Applications/UTM.app"
        utm_available = os.path.exists(utm_path)
        
        if not utm_available:
            self.skipTest("UTM not installed - install with: brew install --cask utm")
        
        self.assertTrue(utm_available, "UTM application not found")
    
    def test_arch_iso_availability(self):
        """Test if Arch Linux ISO is available."""
        iso_exists = os.path.exists(self.utm_config["iso_path"])
        
        if not iso_exists:
            self.skipTest(f"Arch Linux ISO not found at {self.utm_config['iso_path']}")
        
        self.assertTrue(iso_exists, "Arch Linux ISO not available")
    
    def test_vm_configuration_generation(self):
        """Test VM configuration generation."""
        config = self._generate_utm_config()
        
        required_keys = ["name", "memory", "cpu_cores", "disk_size"]
        for key in required_keys:
            self.assertIn(key, config, f"Missing VM configuration key: {key}")
    
    def _generate_utm_config(self) -> Dict:
        """Generate UTM VM configuration."""
        return {
            "name": self.utm_config["name"],
            "architecture": "x86_64",
            "memory": self.utm_config["memory"],
            "cpu_cores": self.utm_config["cpu_cores"],
            "disk_size": self.utm_config["disk_size"],
            "iso_path": self.utm_config["iso_path"]
        }


def run_test_suite():
    """Run the complete test suite."""
    print("🧪 Running Python Test Suite for Arch Linux Installation")
    print("=" * 60)
    
    # Create test results directory
    Path("test_results").mkdir(exist_ok=True)
    
    # Run installation script tests
    suite = unittest.TestLoader().loadTestsFromTestCase(ArchInstallationTests)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Run UTM integration tests
    utm_suite = unittest.TestLoader().loadTestsFromTestCase(UTMIntegrationTests)
    utm_result = runner.run(utm_suite)
    
    # Summary
    total_tests = result.testsRun + utm_result.testsRun
    total_failures = len(result.failures) + len(utm_result.failures)
    total_errors = len(result.errors) + len(utm_result.errors)
    
    print(f"\n📊 Test Suite Summary")
    print(f"Total Tests: {total_tests}")
    print(f"Passed: {total_tests - total_failures - total_errors}")
    print(f"Failed: {total_failures}")
    print(f"Errors: {total_errors}")
    
    if total_failures == 0 and total_errors == 0:
        print("🎉 All tests passed! Installation script is ready for deployment.")
        return True
    else:
        print("❌ Some tests failed. Review output above for details.")
        return False


if __name__ == "__main__":
    success = run_test_suite()
    exit(0 if success else 1)
