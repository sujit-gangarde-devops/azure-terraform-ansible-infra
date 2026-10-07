terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # Remote state in Azure Storage (blob lease gives state locking).
  # Values come from backend.hcl: terraform init -backend-config=backend.hcl
  backend "azurerm" {}
}

# Authentication: `az login` locally, or ARM_CLIENT_ID / ARM_CLIENT_SECRET /
# ARM_TENANT_ID / ARM_SUBSCRIPTION_ID environment variables in Jenkins.
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
