# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.91.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
    purge_soft_delete_on_destroy = true
    recover_soft_deleted_key_vaults = true
    }
  }
}

# Create a resource group
resource "azurerm_resource_group" "rgavd1" {
  name     = "rg${var.yourcompany}avd"
  location = "westeurope"
  tags = {
  Environment = "AVD"
  Team = "AVD01"
   }
}

# Create an azure managed identity
resource "azurerm_user_assigned_identity" "rgami1" {
  resource_group_name = azurerm_resource_group.rgavd1.name
  location            = azurerm_resource_group.rgavd1.location
  name = "AvdAmi"
}

# Create AZ role definition
resource "azurerm_role_definition" "roledefinition" {
  name        = "Imageprovider"
  scope       = data.azurerm_subscription.subscription.id
  description = "This is a custom role created via Terraform"

  permissions {
    actions     = [
        "Microsoft.Compute/galleries/read",
        "Microsoft.Compute/galleries/images/read",
        "Microsoft.Compute/galleries/images/versions/read",
        "Microsoft.Compute/galleries/images/versions/write",

        "Microsoft.Compute/images/write",
        "Microsoft.Compute/images/read",
        "Microsoft.Compute/images/delete"
        ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.subscription.id, # /subscriptions/var.yoursubscription
  ]
}

# Assign AZ role 
resource "azurerm_role_assignment" "roleavd" {
  scope                = data.azurerm_subscription.subscription.id
  role_definition_name = azurerm_role_definition.roledefinition.name
  principal_id         = data.azurerm_client_config.account.object_id
}

#Create shared image gallery
resource "azurerm_shared_image_gallery" "sig" {
  name                = "avd_image_gallery"
  resource_group_name = azurerm_resource_group.rgavd1.name
  location            = azurerm_resource_group.rgavd1.location
  description         = "Shared images and things."
}
