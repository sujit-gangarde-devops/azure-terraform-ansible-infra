#!/usr/bin/env bash
# Installs what this pipeline needs on an Ubuntu Jenkins server:
# Terraform, TFLint, Checkov, Ansible, ansible-lint and Azure CLI.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y gnupg software-properties-common curl unzip pipx

# Terraform (official HashiCorp apt repo)
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

# Ansible (official PPA, newer than Ubuntu's default)
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible

# TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Checkov and ansible-lint, installed for the jenkins user
sudo -u jenkins -H pipx install checkov
sudo -u jenkins -H pipx install ansible-lint
sudo -u jenkins -H pipx ensurepath

# Azure CLI (skip if already installed for Project 1)
command -v az >/dev/null || curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

sudo systemctl restart jenkins
terraform -version; ansible --version | head -1; tflint --version; az version -o tsv | head -1
