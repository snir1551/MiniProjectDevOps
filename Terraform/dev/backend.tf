terraform {
  backend "azurerm" {
    resource_group_name  = "dev-rg"
    storage_account_name = "mtcstatetf"
    container_name       = "tfstate-dev"
    key                  = "terraform.tfstate"
  }
}

