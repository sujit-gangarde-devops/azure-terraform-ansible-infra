#!/usr/bin/env bash
# One-time setup: storage account that holds Terraform remote state.
# Kept outside the main Terraform code so destroying the infra never deletes its own state.
set -euo pipefail

RESOURCE_GROUP="rg-tfstate"
LOCATION="centralindia"
STORAGE_ACCOUNT="sttfstate$(openssl rand -hex 3)"   # must be globally unique
CONTAINER="tfstate"

az group create --name "$RESOURCE_GROUP" --location "$LOCATION" -o none

az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  -o none

# Versioning + soft delete let you recover an older state file if something goes wrong
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 7 \
  -o none

az storage container create --name "$CONTAINER" --account-name "$STORAGE_ACCOUNT" -o none

echo "Remote state backend ready. Put this in environments/dev/backend.hcl:"
echo "  resource_group_name  = \"$RESOURCE_GROUP\""
echo "  storage_account_name = \"$STORAGE_ACCOUNT\""
echo "  container_name       = \"$CONTAINER\""
echo "  key                  = \"webapp/dev.tfstate\""
