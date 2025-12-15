#!/bin/bash
set -e

apt-get update -y && apt-get install -y \
    curl wget jq git gh 

# Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y terraform

# TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Terraform-docs
curl -Lo terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.17.0/terraform-docs-v0.17.0-linux-amd64.tar.gz
tar xzf terraform-docs.tar.gz && mv terraform-docs /usr/local/bin/

# Git config
git config --global user.name "Coder AI Task"
git config --global user.email "task@coder.local"
