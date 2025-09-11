#!/bin/bash
# TUI Display Module - 10-line compact interface with rainbow progress bars
# Colors for the rainbow progress bars (violet to red)

# TUI Configuration
TUI_HEIGHT=10
PROGRESS_LINES=3
LOG_LINES=5
INPUT_LINES=2

# Rainbow colors (violet to red)
declare -a RAINBOW_COLORS=(
    '\033[38;5;129m'  # Violet
    '\033[38;5;63m'   # Indigo  
    '\033[38;5;33m'   # Blue
    '\033[38;5;46m'   # Green
    '\033[38;5;226m'  # Yellow
    '\033[38;5;208m'  # Orange
    '\033[38;5;196m'  # Red
)

# Text contrast colors for each rainbow background
declare -a CONTRAST_COLORS=(
    '\033[97m'        # White text on violet
    '\033[97m'        # White text on indigo
    '\033[97m'        # White text on blue
    '\033[30m'        # Black text on green
    '\033[30m'        # Black text on yellow
    '\033[30m'        # Black text on orange
    '\033[97m'        # White text on red
)

NC='\033[0m'          # No Color
BOLD='\033[1m'        # Bold text
CLEAR_LINE='\033[2K'  # Clear entire line
CURSOR_UP='\033[1A'   # Move cursor up one line

# Global variables for TUI state
CURRENT_MODULE_INDEX=0
declare -a MODULE_PROGRESS=(0 0 0 0 0 0 0 0 0)  # Progress for each module (0-100)
declare -a LOG_BUFFER=()                          # Circular buffer for log messages
LOG_BUFFER_SIZE=5
CURRENT_LOG_INDEX=0

# Configuration mode tracking
INSTALLATION_MODE="MANUAL"    # Can be: MANUAL, CONFIG, AUTO
CONFIG_NAME=""                # Name of config file if using config mode

# Module names for display
declare -a MODULE_NAMES=(
    "DISK"
    "FS"
    "BASE"
    "SYS"
    "HW"
    "DRV"
    "TDP"
    "DESK"
    "GAME"
)

# Initialize TUI
init_tui() {
    # Clear screen and hide cursor
    clear
    printf '\033[?25l'  # Hide cursor
    
    # Print initial TUI frame
    draw_tui_frame
}

# Cleanup TUI
cleanup_tui() {
    # Show cursor and restore normal terminal
    printf '\033[?25h'  # Show cursor
    echo ""
}

# Draw the complete TUI frame
draw_tui_frame() {
    # Move to top of TUI area
    printf '\033[1;1H'
    
    # Draw progress bars (lines 1-3)
    draw_progress_bars
    
    # Draw separator
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    # Draw log area (lines 5-9)
    draw_log_area
    
    # Draw input area (lines 10-11)
    draw_input_area
}

# Draw rainbow progress bars with current module percentage
draw_progress_bars() {
    local total_modules=${#MODULE_NAMES[@]}
    local bar_width=8  # Width of each progress bar
    local current_percentage=${MODULE_PROGRESS[$CURRENT_MODULE_INDEX]}
    
    # Line 1: Module names with configuration mode indicator
    local mode_indicator=""
    case "$INSTALLATION_MODE" in
        "CONFIG")
            mode_indicator=" ${BOLD}[CONFIG: ${CONFIG_NAME}]${NC}"
            ;;
        "AUTO")
            mode_indicator=" ${BOLD}[AUTO]${NC}"
            ;;
        "MANUAL")
            mode_indicator=" ${BOLD}[MANUAL]${NC}"
            ;;
    esac
    
    printf "${BOLD}Modules:${mode_indicator} ${NC}"
    for i in "${!MODULE_NAMES[@]}"; do
        local color_index=$((i % ${#RAINBOW_COLORS[@]}))
        printf "${RAINBOW_COLORS[$color_index]}${CONTRAST_COLORS[$color_index]} ${MODULE_NAMES[$i]} ${NC}"
    done
    echo ""
    
    # Line 2: Progress bars
    printf "${BOLD}Progress:${NC}"
    for i in "${!MODULE_NAMES[@]}"; do
        local color_index=$((i % ${#RAINBOW_COLORS[@]}))
        local progress=${MODULE_PROGRESS[$i]}
        
        # Calculate filled and empty portions
        local filled_chars=$((progress * bar_width / 100))
        local empty_chars=$((bar_width - filled_chars))
        
        # Draw progress bar
        printf "${RAINBOW_COLORS[$color_index]}"
        printf "%.0s█" $(seq 1 $filled_chars)
        printf "%.0s░" $(seq 1 $empty_chars)
        printf "${NC}"
    done
    echo ""
    
    # Line 3: Current module percentage (centered in current module bar)
    printf "${BOLD}Status:  ${NC}"
    for i in "${!MODULE_NAMES[@]}"; do
        local color_index=$((i % ${#RAINBOW_COLORS[@]}))
        
        if [[ $i -eq $CURRENT_MODULE_INDEX ]]; then
            # Show percentage in current module with contrasting color
            printf "${RAINBOW_COLORS[$color_index]}${CONTRAST_COLORS[$color_index]}${BOLD}"
            printf "%*s" $(((bar_width + 3) / 2)) "${current_percentage}%"
            printf "%*s" $(((bar_width - 3) / 2)) ""
            printf "${NC}"
        else
            # Show status for other modules
            local status=""
            if [[ ${MODULE_PROGRESS[$i]} -eq 100 ]]; then
                status="✓"
            elif [[ ${MODULE_PROGRESS[$i]} -gt 0 ]]; then
                status="..."
            else
                status="○"
            fi
            printf "${RAINBOW_COLORS[$color_index]}${CONTRAST_COLORS[$color_index]}"
            printf "%*s" $(((bar_width + 1) / 2)) "$status"
            printf "%*s" $(((bar_width - 1) / 2)) ""
            printf "${NC}"
        fi
    done
    echo ""
}

# Draw log area showing recent messages
draw_log_area() {
    local line_count=0
    
    # Display recent log messages
    for ((i=0; i<LOG_BUFFER_SIZE; i++)); do
        local log_index=$(((CURRENT_LOG_INDEX - LOG_BUFFER_SIZE + i + LOG_BUFFER_SIZE) % LOG_BUFFER_SIZE))
        
        if [[ -n "${LOG_BUFFER[$log_index]}" ]]; then
            echo "${LOG_BUFFER[$log_index]}"
        else
            echo ""
        fi
        ((line_count++))
    done
    
    # Fill remaining lines with empty space
    while [[ $line_count -lt $LOG_LINES ]]; do
        echo ""
        ((line_count++))
    done
}

# Draw input area
draw_input_area() {
    echo "────────────────────────────────────────────────────────────────────────────────"
    printf "${BOLD}Input: ${NC}"
}

# Update progress for specific module
update_module_progress() {
    local module_index="$1"
    local progress="$2"
    
    if [[ $module_index -ge 0 && $module_index -lt ${#MODULE_PROGRESS[@]} ]]; then
        MODULE_PROGRESS[$module_index]=$progress
        
        # If module completed, move to next module
        if [[ $progress -eq 100 && $module_index -eq $CURRENT_MODULE_INDEX ]]; then
            CURRENT_MODULE_INDEX=$((module_index + 1))
            if [[ $CURRENT_MODULE_INDEX -ge ${#MODULE_NAMES[@]} ]]; then
                CURRENT_MODULE_INDEX=$((${#MODULE_NAMES[@]} - 1))
            fi
        fi
        
        redraw_progress_area
    fi
}

# Add message to log buffer
add_log_message() {
    local message="$1"
    local timestamp=$(date '+%H:%M:%S')
    
    # Add timestamped message to circular buffer
    LOG_BUFFER[$CURRENT_LOG_INDEX]="[$timestamp] $message"
    CURRENT_LOG_INDEX=$(((CURRENT_LOG_INDEX + 1) % LOG_BUFFER_SIZE))
    
    redraw_log_area
}

# Redraw only the progress area (lines 1-3)
redraw_progress_area() {
    # Save cursor position
    printf '\033[s'
    
    # Move to progress area and redraw
    printf '\033[1;1H'
    draw_progress_bars
    
    # Restore cursor position
    printf '\033[u'
}

# Redraw only the log area (lines 5-9)
redraw_log_area() {
    # Save cursor position
    printf '\033[s'
    
    # Move to log area and redraw
    printf '\033[5;1H'
    draw_log_area
    
    # Restore cursor position
    printf '\033[u'
}

# Get user input with prompt
tui_read_input() {
    local prompt="$1"
    local input=""
    
    # Position cursor at input line
    printf '\033[11;8H'
    printf "${CLEAR_LINE}$prompt "
    read -r input
    
    echo "$input"
}

# Show confirmation dialog
tui_confirm() {
    local message="$1"
    local response=""
    
    add_log_message "$message"
    response=$(tui_read_input "(y/n):")
    
    [[ "$response" =~ ^[Yy] ]]
}

# Demo function to test TUI
demo_tui() {
    init_tui
    
    # Demo different modes
    echo "Testing TUI modes..."
    
    # Test CONFIG mode
    tui_set_mode "CONFIG" "zen"
    add_log_message "Demo: CONFIG mode (zen.conf)"
    sleep 2
    
    # Test MANUAL mode
    tui_set_mode "MANUAL" ""
    add_log_message "Demo: MANUAL mode (user prompts)"
    sleep 2
    
    # Test AUTO mode
    tui_set_mode "AUTO" ""
    add_log_message "Demo: AUTO mode (default settings)"
    sleep 2
    
    # Simulate installation progress
    for module_idx in $(seq 0 8); do
        CURRENT_MODULE_INDEX=$module_idx
        add_log_message "Starting ${MODULE_NAMES[$module_idx]} module..."
        
        for progress in $(seq 0 10 100); do
            update_module_progress $module_idx $progress
            sleep 0.1
        done
        
        add_log_message "${MODULE_NAMES[$module_idx]} module completed ✓"
        sleep 0.5
    done
    
    add_log_message "Installation completed successfully! 🎉"
    
    # Test input
    username=$(tui_read_input "Enter username:")
    add_log_message "Username set to: $username"
    
    if tui_confirm "Reboot system now?"; then
        add_log_message "Rebooting system..."
    else
        add_log_message "Reboot cancelled"
    fi
    
    sleep 2
    cleanup_tui
}

# Set installation mode for TUI display
tui_set_mode() {
    local mode="$1"
    local config_name="$2"
    
    INSTALLATION_MODE="$mode"
    CONFIG_NAME="$config_name"
    
    # Update display if TUI is active
    if [[ -n "$TUI_ENABLED" ]]; then
        redraw_progress_area
    fi
}

# Integration functions for use with core_installation.sh
tui_start_module() {
    local module_name="$1"
    local module_index="$2"
    
    CURRENT_MODULE_INDEX=$module_index
    MODULE_PROGRESS[$module_index]=0
    add_log_message "Starting module: $module_name"
    redraw_progress_area
}

tui_update_progress() {
    local module_index="$1"
    local progress="$2"
    local message="$3"
    
    update_module_progress $module_index $progress
    
    if [[ -n "$message" ]]; then
        add_log_message "$message"
    fi
}

tui_complete_module() {
    local module_name="$1"
    local module_index="$2"
    
    update_module_progress $module_index 100
    add_log_message "✓ $module_name completed"
}

tui_error() {
    local error_message="$1"
    add_log_message "❌ ERROR: $error_message"
}

tui_warning() {
    local warning_message="$1"
    add_log_message "⚠️  WARNING: $warning_message"
}

# Main function for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Run demo if script is executed directly
    demo_tui
fi
