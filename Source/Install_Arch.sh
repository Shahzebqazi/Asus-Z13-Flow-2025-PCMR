#!/bin/bash
# Arch Linux Installation Script for ASUS ROG Flow Z13 (2025)
# ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+
# Author: sqazi
# Version: 2.0.0
# Date: September 11, 2025

# This is a symlink/redirect to the main installation script
# The Source directory is maintained for development and testing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/../Install_Arch.sh"

if [[ -f "$MAIN_SCRIPT" ]]; then
    echo "Redirecting to main installation script..."
    exec "$MAIN_SCRIPT" "$@"
else
    echo "Error: Main installation script not found at $MAIN_SCRIPT"
    exit 1
fi
