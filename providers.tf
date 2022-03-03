terraform {
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}
