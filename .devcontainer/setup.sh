#!/bin/bash
set -e

echo "Installing dependencies..."

if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo -E bash "$0" "$@"
  fi
  echo "This script must run as root (sudo not available)." >&2
  exit 1
fi

apt-get update -y && apt-get install -y \
    ca-certificates curl wget jq git gh gnupg lsb-release unzip

# Install CA cert from parent workspace container (if available)
if [ -f /coder-ca/ca-certificates.crt ]; then
  echo "Installing internal CA certificates..."
  cp /coder-ca/ca-certificates.crt /usr/local/share/ca-certificates/internal-ca.crt
  update-ca-certificates
fi 

# Terraform
mkdir -p /usr/share/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
apt-get update && apt-get install -y terraform

# TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Terraform-docs
arch="$(uname -m)"
case "$arch" in
  x86_64) td_arch="amd64" ;;
  aarch64|arm64) td_arch="arm64" ;;
  *) echo "Unsupported architecture for terraform-docs: $arch" >&2; exit 1 ;;
esac
curl -Lo terraform-docs.tar.gz "https://github.com/terraform-docs/terraform-docs/releases/download/v0.17.0/terraform-docs-v0.17.0-linux-${td_arch}.tar.gz"
tar xzf terraform-docs.tar.gz
mv terraform-docs /usr/local/bin/
rm -f terraform-docs.tar.gz

# Git config
if [ -n "${SUDO_USER:-}" ] && id "$SUDO_USER" >/dev/null 2>&1; then
  sudo -u "$SUDO_USER" git config --global user.name "Coder AI Task"
  sudo -u "$SUDO_USER" git config --global user.email "task@coder.local"
else
  git config --global user.name "Coder AI Task"
  git config --global user.email "task@coder.local"
fi
