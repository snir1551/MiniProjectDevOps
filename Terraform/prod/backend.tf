terraform {
  backend "azurerm" {
    resource_group_name  = "prod-rg"
    storage_account_name = "mtcstatetf"
    container_name       = "tfstate-prod"
    key                  = "terraform.tfstate"
  }
}

