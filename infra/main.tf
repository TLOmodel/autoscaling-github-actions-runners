resource "azurerm_resource_group" "aks" {
  location = "uksouth"
  name     = "tlo-aks-${var.azure_suffix}" # resource group name
}
