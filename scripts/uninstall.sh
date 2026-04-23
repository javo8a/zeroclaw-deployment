#!/bin/bash
set -e

# ZeroClaw Uninstallation Script for Fedora x86_64

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

ZEROCLAW_USER="zeroclaw"
ZEROCLAW_HOME="/home/$ZEROCLAW_USER"
BINARY_DEST="/usr/local/bin/zeroclaw"
SERVICE_DEST="/etc/systemd/system/zeroclaw.service"

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

stop_service() {
    if systemctl is-active --quiet zeroclaw; then
        log_info "Stopping zeroclaw service..."
        systemctl stop zeroclaw
        log_success "Service stopped"
    fi

    if systemctl is-enabled --quiet zeroclaw 2>/dev/null; then
        log_info "Disabling zeroclaw service..."
        systemctl disable zeroclaw
        log_success "Service disabled"
    fi
}

remove_service() {
    if [[ -f "$SERVICE_DEST" ]]; then
        log_info "Removing systemd service file..."
        rm -f "$SERVICE_DEST"
        systemctl daemon-reload
        log_success "Service file removed"
    fi
}

remove_binary() {
    if [[ -f "$BINARY_DEST" ]]; then
        log_info "Removing zeroclaw binary..."
        rm -f "$BINARY_DEST"
        log_success "Binary removed"
    fi
}

remove_user_and_config() {
    echo
    log_warning "Do you want to remove the zeroclaw user and all configuration data?"
    log_warning "This will delete $ZEROCLAW_HOME and all its contents."
    read -p "Remove user and data? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if id "$ZEROCLAW_USER" &>/dev/null; then
            log_info "Removing user '$ZEROCLAW_USER' and home directory..."
            userdel -r "$ZEROCLAW_USER" 2>/dev/null || {
                log_warning "Could not remove user with userdel, trying manual cleanup..."
                rm -rf "$ZEROCLAW_HOME"
                userdel "$ZEROCLAW_USER" 2>/dev/null || true
            }
            log_success "User and configuration removed"
        fi
    else
        log_info "Keeping user and configuration data at $ZEROCLAW_HOME"
    fi
}

main() {
    log_info "Starting ZeroClaw uninstallation..."
    echo

    check_root

    stop_service
    remove_service
    remove_binary
    remove_user_and_config

    echo
    log_success "Uninstallation complete!"
    echo
}

main "$@"
