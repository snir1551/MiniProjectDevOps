terraform {
  backend "azurerm" {
    resource_group_name  = "dev-rg"
    storage_account_name = "mtcstatetfdev"
    container_name       = "tfstate-dev"
    key                  = "terraform.dev.tfstate"
  }
}

