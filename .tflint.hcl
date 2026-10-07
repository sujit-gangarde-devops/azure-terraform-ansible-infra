plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Azure-specific checks (invalid VM sizes, regions, etc.). Use the latest release from
# https://github.com/terraform-linters/tflint-ruleset-azurerm/releases
plugin "azurerm" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
