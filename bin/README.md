# Binary Directory

Place the compiled `zeroclaw` binary in this directory.

## Building ZeroClaw for Fedora x86_64

On your Fedora x86_64 system:

```bash
# Install Rust if not already installed
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Install build dependencies
sudo dnf install -y gcc pkg-config openssl-devel

# Clone and build zeroclaw
git clone https://github.com/zeroclaw-labs/zeroclaw.git
cd zeroclaw
cargo build --release --locked

# The binary will be at: target/release/zeroclaw
# Copy it to this directory:
cp target/release/zeroclaw /path/to/this/repo/bin/
```

## Verifying the Binary

After copying, verify the binary:

```bash
# Check it's the correct architecture
file zeroclaw
# Should output: zeroclaw: ELF 64-bit LSB executable, x86-64, ...

# Make it executable
chmod +x zeroclaw

# Test it runs
./zeroclaw --version
```
