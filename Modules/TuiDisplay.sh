#!/bin/bash

# Minimal TUI shim for stable core installer
# Provides no-op implementations so the main script can run without full TUI

init_tui() {
    :
}

cleanup_tui() {
    :
}

add_log_message() {
    local message="$1"
    echo "$message"
}

tui_set_mode() {
    :
}

tui_warning() {
    local message="$1"
    echo "[WARN] $message"
}

tui_error() {
    local message="$1"
    echo "[ERROR] $message"
}
