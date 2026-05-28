#!/bin/bash
set -e

# Helper script to build zeroclaw on Fedora x86_64

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$REPO_DIR/build"
ZEROCLAW_REPO="https://github.com/zeroclaw-labs/zeroclaw.git"

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

check_arch() {
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
        log_error "This script should be run on x86_64 (64-bit Intel/AMD) architecture"
        log_error "Current architecture: $ARCH"
        exit 1
    fi
}

check_rust() {
    if ! command -v cargo &> /dev/null; then
        log_warning "Rust is not installed"
        log_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        log_success "Rust installed"
    else
        log_info "Rust is already installed: $(rustc --version)"
    fi
}

install_dependencies() {
    log_info "Installing build dependencies..."

    if command -v dnf &> /dev/null; then
        sudo dnf install -y gcc pkg-config openssl-devel git nodejs npm
    elif command -v yum &> /dev/null; then
        sudo yum install -y gcc pkg-config openssl-devel git nodejs npm
    else
        log_error "Could not find dnf or yum package manager"
        exit 1
    fi

    log_success "Dependencies installed"
}

clone_zeroclaw() {
    log_info "Cloning zeroclaw repository..."

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    if [[ -d "zeroclaw" ]]; then
        log_info "zeroclaw directory already exists, pulling latest changes..."
        cd zeroclaw
        git pull
    else
        git clone "$ZEROCLAW_REPO"
        cd zeroclaw
    fi

    log_success "Repository ready"
}

build_web_dashboard() {
    log_info "Building web dashboard (cargo web build)..."

    cd "$BUILD_DIR/zeroclaw"
    if ! command -v npm &> /dev/null; then
        log_error "npm is required to build the web dashboard"
        exit 1
    fi
    cargo web build

    if [[ ! -f "$BUILD_DIR/zeroclaw/web/dist/index.html" ]]; then
        log_error "web/dist/index.html not found after cargo web build"
        exit 1
    fi

    log_success "Web dashboard built"
}

build_zeroclaw() {
    log_info "Building zeroclaw binary (this may take several minutes)..."

    cd "$BUILD_DIR/zeroclaw"
    cargo build --release --locked

    log_success "Build complete"
}

copy_binary() {
    log_info "Copying binary to bin directory..."

    BINARY_SRC="$BUILD_DIR/zeroclaw/target/release/zeroclaw"
    BINARY_DEST="$REPO_DIR/bin/zeroclaw"

    if [[ ! -f "$BINARY_SRC" ]]; then
        log_error "Binary not found at $BINARY_SRC"
        exit 1
    fi

    cp "$BINARY_SRC" "$BINARY_DEST"
    chmod +x "$BINARY_DEST"

    log_success "Binary copied to $BINARY_DEST"
}

copy_web_dist() {
    log_info "Copying web dashboard to web/dist..."

    WEB_SRC="$BUILD_DIR/zeroclaw/web/dist"
    WEB_DEST="$REPO_DIR/web/dist"

    if [[ ! -f "$WEB_SRC/index.html" ]]; then
        log_error "Web dashboard not found at $WEB_SRC"
        exit 1
    fi

    rm -rf "$WEB_DEST"
    cp -a "$WEB_SRC" "$WEB_DEST"

    log_success "Web dashboard copied to $WEB_DEST"
}

verify_binary() {
    log_info "Verifying binary..."

    BINARY="$REPO_DIR/bin/zeroclaw"

    echo
    log_info "File information:"
    file "$BINARY"

    echo
    log_info "Binary size:"
    ls -lh "$BINARY"

    echo
    log_info "Testing binary..."
    if "$BINARY" --version 2>/dev/null || "$BINARY" --help 2>/dev/null; then
        log_success "Binary is executable and working"
    else
        log_warning "Binary runs but may need configuration"
    fi
}

main() {
    log_info "Starting zeroclaw build process for Fedora x86_64..."
    echo

    check_arch
    check_rust
    install_dependencies
    clone_zeroclaw
    build_web_dashboard
    build_zeroclaw
    copy_binary
    copy_web_dist
    verify_binary

    echo
    log_success "Build complete!"
    echo
    log_info "Next steps:"
    log_info "  1. Run the installation script: sudo ./scripts/install.sh"
    log_info "  2. Configure zeroclaw: sudo -u zeroclaw zeroclaw onboard"
    log_info "  3. Start the service: sudo systemctl start zeroclaw"
    echo
}

main "$@"
