# ZeroClaw Deployment for Fedora x86_64

This repository provides installation scripts and configuration for deploying [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) on Fedora x86_64 systems.

## What is ZeroClaw?

ZeroClaw is a lightweight, Rust-based personal AI assistant infrastructure that provides:
- Multi-channel messaging support (WhatsApp, Telegram, Slack, Discord, Signal, Matrix)
- Web dashboard for real-time control and monitoring
- Hardware integration (ESP32, Arduino, Raspberry Pi)
- Autonomous agent orchestration with scheduling capabilities
- Local-first architecture with minimal resource requirements

## Prerequisites

- Fedora Linux running on x86_64 (64-bit Intel/AMD) architecture
- Root or sudo access for installation
- Internet connection for downloading dependencies

## Repository Structure

```
.
├── bin/                    # Place the compiled zeroclaw binary here
├── config/                 # Configuration templates
├── scripts/                # Installation and setup scripts
├── systemd/                # Systemd service files
└── README.md              # This file
```

## Quick Start

### 1. Build ZeroClaw for x86_64

On a Fedora x86_64 system with Rust installed:

```bash
# Install Rust if not already installed
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Clone and build zeroclaw
git clone https://github.com/zeroclaw-labs/zeroclaw.git
cd zeroclaw
cargo build --release --locked

# Copy the binary to this repo
cp target/release/zeroclaw /path/to/this/repo/bin/
```

### 2. Run the Installation Script

```bash
cd /path/to/this/repo
sudo ./scripts/install.sh
```

This will:
- Create a dedicated `zeroclaw` user
- Install the zeroclaw binary to `/usr/local/bin`
- Set up configuration directory at `/home/zeroclaw/.zeroclaw`
- Configure proper permissions
- Install and enable systemd service

### 3. Configure ZeroClaw

Edit the configuration file:

```bash
sudo nano /home/zeroclaw/.zeroclaw/config.toml
```

Add your API key and provider settings:

```toml
default_provider = "anthropic"
api_key = "sk-ant-your-key-here"
```

### 4. Start the Service

```bash
sudo systemctl start zeroclaw
sudo systemctl status zeroclaw
```

To enable automatic startup on boot:

```bash
sudo systemctl enable zeroclaw
```

## Manual Installation

If you prefer to install manually, follow these steps:

### 1. Create dedicated user

```bash
sudo useradd -r -m -d /home/zeroclaw -s /bin/bash zeroclaw
```

### 2. Install the binary

```bash
sudo install -m 755 bin/zeroclaw /usr/local/bin/zeroclaw
```

### 3. Set up configuration

```bash
sudo mkdir -p /home/zeroclaw/.zeroclaw
sudo cp config/config.toml.template /home/zeroclaw/.zeroclaw/config.toml
sudo chown -R zeroclaw:zeroclaw /home/zeroclaw/.zeroclaw
sudo chmod 700 /home/zeroclaw/.zeroclaw
sudo chmod 600 /home/zeroclaw/.zeroclaw/config.toml
```

### 4. Install systemd service

```bash
sudo cp systemd/zeroclaw.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable zeroclaw
sudo systemctl start zeroclaw
```

## Management Commands

```bash
# Check status
sudo systemctl status zeroclaw

# View logs
sudo journalctl -u zeroclaw -f

# Restart service
sudo systemctl restart zeroclaw

# Stop service
sudo systemctl stop zeroclaw

# Disable automatic startup
sudo systemctl disable zeroclaw
```

## Updating ZeroClaw

To update to a new version:

```bash
# Stop the service
sudo systemctl stop zeroclaw

# Replace the binary
sudo install -m 755 bin/zeroclaw /usr/local/bin/zeroclaw

# Start the service
sudo systemctl start zeroclaw
```

## Uninstallation

```bash
sudo ./scripts/uninstall.sh
```

This will remove the service, binary, and optionally the zeroclaw user and configuration.

## Security Considerations

- The zeroclaw user is a system user with limited privileges
- Configuration files are readable only by the zeroclaw user (600 permissions)
- The configuration directory is accessible only by the zeroclaw user (700 permissions)
- The service runs as an unprivileged user
- API keys and sensitive data are stored in the user's home directory

## Troubleshooting

### Service fails to start

The systemd unit must run `zeroclaw daemon` (not bare `zeroclaw`). Without the `daemon` subcommand the process exits immediately and systemd reports a failed service.

Check the logs:
```bash
sudo journalctl -u zeroclaw -n 50
```

After updating the unit file:
```bash
sudo cp systemd/zeroclaw.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart zeroclaw
```

### Web console not reachable from other machines

The gateway defaults to `127.0.0.1:42617`. Edit `/home/zeroclaw/.zeroclaw/config.toml`:

```toml
[gateway]
host = "0.0.0.0"
port = 42617
allow_public_bind = true
```

Then restart: `sudo systemctl restart zeroclaw`

On Fedora, allow the port through the firewall:

```bash
sudo firewall-cmd --permanent --add-port=42617/tcp
sudo firewall-cmd --reload
```

Open `http://<server-ip>:42617` from another device. Pairing is required by default — run `sudo -u zeroclaw zeroclaw gateway paircode` on the server if prompted.

For access over the public internet, prefer a reverse proxy with TLS or a `[tunnel]` provider rather than exposing `42617` directly.

### Permission denied errors

Ensure proper ownership:
```bash
sudo chown -R zeroclaw:zeroclaw /home/zeroclaw/.zeroclaw
```

### Binary not found

Verify the binary is installed:
```bash
which zeroclaw
ls -l /usr/local/bin/zeroclaw
```

## Contributing

Feel free to submit issues or pull requests to improve these deployment scripts.

## License

These deployment scripts are provided as-is. ZeroClaw itself is subject to its own license terms.
