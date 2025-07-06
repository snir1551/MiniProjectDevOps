terraform {
  backend "azurerm" {
    resource_group_name  = "mtc-resources"
    storage_account_name = "mtcstatetf"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

