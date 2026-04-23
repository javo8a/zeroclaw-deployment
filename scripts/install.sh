#!/bin/bash
set -e

# ZeroClaw Installation Script for Fedora x86_64
# This script installs zeroclaw as a system service with proper user permissions

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ZEROCLAW_USER="zeroclaw"
ZEROCLAW_HOME="/home/$ZEROCLAW_USER"
ZEROCLAW_CONFIG_DIR="$ZEROCLAW_HOME/.zeroclaw"
BINARY_SOURCE="$REPO_DIR/bin/zeroclaw"
BINARY_DEST="/usr/local/bin/zeroclaw"
SERVICE_FILE="$REPO_DIR/systemd/zeroclaw.service"
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

check_arch() {
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
        log_warning "This system is $ARCH, not x86_64. Installation may not work correctly."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

check_binary() {
    if [[ ! -f "$BINARY_SOURCE" ]]; then
        log_error "ZeroClaw binary not found at $BINARY_SOURCE"
        log_info "Please build zeroclaw and place the binary in $REPO_DIR/bin/"
        log_info ""
        log_info "To build zeroclaw:"
        log_info "  git clone https://github.com/zeroclaw-labs/zeroclaw.git"
        log_info "  cd zeroclaw"
        log_info "  cargo build --release --locked"
        log_info "  cp target/release/zeroclaw $REPO_DIR/bin/"
        exit 1
    fi

    if [[ ! -x "$BINARY_SOURCE" ]]; then
        log_error "Binary at $BINARY_SOURCE is not executable"
        chmod +x "$BINARY_SOURCE"
        log_success "Made binary executable"
    fi
}

create_user() {
    if id "$ZEROCLAW_USER" &>/dev/null; then
        log_info "User '$ZEROCLAW_USER' already exists"
    else
        log_info "Creating system user '$ZEROCLAW_USER'..."
        useradd -r -m -d "$ZEROCLAW_HOME" -s /bin/bash -c "ZeroClaw Service User" "$ZEROCLAW_USER"
        log_success "User '$ZEROCLAW_USER' created"
    fi
}

install_binary() {
    log_info "Installing zeroclaw binary to $BINARY_DEST..."
    install -m 755 "$BINARY_SOURCE" "$BINARY_DEST"
    log_success "Binary installed"
}

setup_config() {
    log_info "Setting up configuration directory..."

    # Create config directory
    mkdir -p "$ZEROCLAW_CONFIG_DIR"

    # Copy template config if it doesn't exist
    if [[ ! -f "$ZEROCLAW_CONFIG_DIR/config.toml" ]]; then
        if [[ -f "$REPO_DIR/config/config.toml.template" ]]; then
            cp "$REPO_DIR/config/config.toml.template" "$ZEROCLAW_CONFIG_DIR/config.toml"
            log_success "Configuration template installed"
            log_warning "Please edit $ZEROCLAW_CONFIG_DIR/config.toml to add your API keys"
        else
            # Create minimal config
            cat > "$ZEROCLAW_CONFIG_DIR/config.toml" << 'EOF'
# ZeroClaw Configuration
# Edit this file to add your API keys and configure channels

# Default AI provider (anthropic, openai, etc.)
default_provider = "anthropic"

# API key for the default provider
# api_key = "sk-ant-your-key-here"

# Optional: Configure specific channels
# [channels.telegram]
# enabled = false
# bot_token = "your-telegram-bot-token"

# [channels.discord]
# enabled = false
# bot_token = "your-discord-bot-token"
EOF
            log_success "Minimal configuration file created"
            log_warning "Please edit $ZEROCLAW_CONFIG_DIR/config.toml to add your API keys"
        fi
    else
        log_info "Configuration file already exists, skipping template copy"
    fi

    # Set proper permissions
    chown -R "$ZEROCLAW_USER:$ZEROCLAW_USER" "$ZEROCLAW_CONFIG_DIR"
    chmod 700 "$ZEROCLAW_CONFIG_DIR"
    chmod 600 "$ZEROCLAW_CONFIG_DIR/config.toml"
    log_success "Permissions set (700 for directory, 600 for config file)"
}

install_service() {
    log_info "Installing systemd service..."

    if [[ -f "$SERVICE_FILE" ]]; then
        cp "$SERVICE_FILE" "$SERVICE_DEST"
    else
        log_warning "Service file not found at $SERVICE_FILE, creating default service"
        cat > "$SERVICE_DEST" << EOF
[Unit]
Description=ZeroClaw Personal AI Assistant
After=network.target

[Service]
Type=simple
User=$ZEROCLAW_USER
Group=$ZEROCLAW_USER
WorkingDirectory=$ZEROCLAW_HOME
ExecStart=$BINARY_DEST
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$ZEROCLAW_CONFIG_DIR

[Install]
WantedBy=multi-user.target
EOF
    fi

    systemctl daemon-reload
    log_success "Systemd service installed"
}

main() {
    log_info "Starting ZeroClaw installation..."
    echo

    check_root
    check_arch
    check_binary

    echo
    create_user
    install_binary
    setup_config
    install_service

    echo
    log_success "Installation complete!"
    echo
    log_info "Next steps:"
    log_info "  1. Edit the configuration: sudo nano $ZEROCLAW_CONFIG_DIR/config.toml"
    log_info "  2. Start the service: sudo systemctl start zeroclaw"
    log_info "  3. Enable auto-start: sudo systemctl enable zeroclaw"
    log_info "  4. Check status: sudo systemctl status zeroclaw"
    log_info "  5. View logs: sudo journalctl -u zeroclaw -f"
    echo
}

main "$@"
