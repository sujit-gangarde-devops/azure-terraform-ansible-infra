# Production-Style Azure Infrastructure with Terraform & Ansible

Modular Terraform provisions a secure, highly-available web tier on Azure; Ansible configures it; a Jenkins pipeline runs the whole thing with static checks, a security scan, a reviewed plan and a manual approval gate.

## Architecture

```
                    Internet
                       │  :80 (HTTP)          :50001-5000N (SSH, admin IPs only)
                       ▼
          ┌──────── Azure Standard Load Balancer (public IP) ────────┐
          │   HTTP probe /health  •  outbound SNAT rule  •  SSH NAT   │
          └──────────────┬──────────────────────┬────────────────────┘
   VNet 10.10.0.0/16     │                      │
   ┌─ snet-web (NSG) ────┼──────────────────────┼──────────────────┐
   │   VM 1 (no public IP)               VM 2 (no public IP)       │
   │   Nginx :80 ─► Tomcat :8080 (localhost only)   Availability Set│
   │   Managed Identity ──► Key Vault (read secrets)               │
   └───────────────────────────┬───────────────────────────────────┘
                               │ 3306 (only from snet-web)
   ┌─ snet-db (NSG, delegated) ▼───────────────────────────────────┐
   │   Azure Database for MySQL Flexible Server (private access)   │
   │   Private DNS zone linked to the VNet                         │
   └───────────────────────────────────────────────────────────────┘
   Terraform state: Azure Storage (versioning + soft delete, blob-lease locking)
```

## Highlights

| Area | What's implemented |
|---|---|
| **IaC** | Reusable modules (`network`, `loadbalancer`, `compute`, `database`, `keyvault`), per-environment root modules, input validation, consistent naming and tagging |
| **State** | Remote backend in Azure Storage with locking, versioning and soft delete; bootstrapped separately so `destroy` never deletes its own state |
| **Network security** | VMs have no public IPs; NSGs with explicit deny; SSH only from allow-listed IPs through LB NAT; MySQL reachable only from the web subnet |
| **High availability** | 2+ VMs in an availability set behind a Standard LB with an app-aware health probe |
| **Secrets** | Generated MySQL password stored in Key Vault; VMs read it via system-assigned managed identity (no credentials on disk) |
| **Config management** | Ansible roles: OS hardening (SSH, unattended upgrades), Tomcat (checksum-verified install, default apps removed, localhost-only, systemd), Nginx reverse proxy |
| **Zero-downtime config** | Playbook runs `serial: 1` so the LB always has a healthy backend |
| **CI/CD** | Jenkins: `fmt` → `validate` → TFLint → Checkov → plan (archived) → manual approval → apply → Ansible → health check; `destroy` goes through the same gates |

## Repository layout

```
bootstrap/                 One-time remote state storage account
modules/                   network, loadbalancer, compute, database, keyvault
environments/dev/          Root module: providers, variables, outputs, inventory template
ansible/                   ansible.cfg, site.yml, roles: common, tomcat, nginx
Jenkinsfile                Plan / approve / apply / configure / verify pipeline
jenkins/install-tools.sh   Terraform, TFLint, Checkov, Ansible, ansible-lint, Azure CLI
```

## Run it locally

```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

./bootstrap/create-tfstate-backend.sh          # once
cd environments/dev
cp backend.hcl.example backend.hcl             # fill in the storage account name
cp terraform.tfvars.example terraform.tfvars   # your IP and SSH public key

terraform init -backend-config=backend.hcl
terraform plan -out=tfplan
terraform apply tfplan

cd ../../ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook playbooks/site.yml

curl "$(terraform -chdir=../environments/dev output -raw app_url)"   # refresh to see both VMs answer
```

Clean up: `terraform destroy` in `environments/dev`, then `az group delete -n rg-tfstate`.

## Screenshots

<!-- Add: Jenkins stage view, approval step, terraform plan output, Azure resource group, app served by both VMs, Checkov report -->
