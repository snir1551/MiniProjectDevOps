terraform {
  backend "azurerm" {
    resource_group_name  = "prod-rg"
    storage_account_name = "mtcstatetfprod"
    container_name       = "tfstate-prod"
    key                  = "terraform.prod.tfstate"
  }
}

