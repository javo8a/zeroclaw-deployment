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

On a Fedora x86_64 system with Rust and Node.js installed:

```bash
# Recommended: builds the binary and web dashboard together
./scripts/build-zeroclaw.sh
```

This runs `cargo web build` (Vite dashboard → `web/dist/`) and `cargo build --release`, then copies artifacts into `bin/zeroclaw` and `web/dist/`.

Manual build (if you prefer):

```bash
git clone https://github.com/zeroclaw-labs/zeroclaw.git
cd zeroclaw
cargo web build
cargo build --release --locked
cp target/release/zeroclaw /path/to/this/repo/bin/
cp -a web/dist /path/to/this/repo/web/
```

### 2. Run the Installation Script

```bash
cd /path/to/this/repo
sudo ./scripts/install.sh
```

This will:
- Create a dedicated `zeroclaw` user
- Install the zeroclaw binary to `/usr/local/bin` and the web dashboard to `/usr/share/zeroclaw/web/dist`
- Set up configuration directory at `/home/zeroclaw/.zeroclaw`
- Configure proper permissions
- Install and enable systemd service

### 3. Configure ZeroClaw

Run the onboarding wizard (recommended for 0.8.0+):

```bash
sudo -u zeroclaw zeroclaw onboard
```

Or edit the config manually. Zeroclaw 0.8.0 uses **schema v3** — providers live under `[providers.models.<type>.<alias>]`, agents under `[agents.<alias>]`, and risk profiles under `[risk_profiles.<alias>]`. See `config/config.toml.template` for a minimal example.

If you upgraded from a pre-0.8.0 config and the web dashboard shows paths that "differ from on-disk", commit the migration:

```bash
sudo systemctl stop zeroclaw
sudo -u zeroclaw zeroclaw config migrate
sudo systemctl start zeroclaw
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

# Replace the binary (and web dashboard if needed)
sudo ./scripts/install.sh

# If upgrading to 0.8.0+, migrate config on disk
sudo -u zeroclaw zeroclaw config migrate

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

### "N paths differ from on-disk" in the web dashboard

This appears when the running daemon loaded a **migrated or edited in-memory config** that does not match `config.toml` on disk. Common after upgrading to 0.8.0 from an older template (`default_provider`, root-level `api_key`, etc.).

Fix:

```bash
sudo systemctl stop zeroclaw
sudo -u zeroclaw zeroclaw config migrate
sudo systemctl start zeroclaw
```

Then complete setup with `sudo -u zeroclaw zeroclaw onboard` if providers/agents are not configured yet. Do **not** click "Reload daemon" alone — that re-reads the stale on-disk file and keeps the drift.

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

### "Web dashboard not available" at :42617

The Rust binary does not include the UI by default. Build the frontend and install it:

```bash
./scripts/build-zeroclaw.sh
sudo ./scripts/install.sh
```

Or on an existing zeroclaw checkout:

```bash
cd zeroclaw
cargo web build
sudo install -d -m 755 /usr/share/zeroclaw/web/dist
sudo cp -a web/dist/. /usr/share/zeroclaw/web/dist/
```

Add to `/home/zeroclaw/.zeroclaw/config.toml`:

```toml
[gateway]
web_dist_dir = "/usr/share/zeroclaw/web/dist"
```

Restart: `sudo systemctl restart zeroclaw`. The API at `:42617` works without the dashboard; only the HTML UI needs `web/dist`.

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
