terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.110" }
  }
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatepayments"
    container_name       = "tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {
    key_vault { purge_soft_delete_on_destroy = false }
  }
  use_oidc = true
}

data "azurerm_client_config" "current" {}

locals {
  name = "${var.service}-${var.environment}"
  tags = merge(var.tags, { environment = var.environment, service = var.service, managed_by = "terraform" })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = local.tags
}

resource "azurerm_key_vault" "this" {
  name                          = "kv-${replace(local.name, "-", "")}"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "premium"
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
  tags = local.tags
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "diag-kv"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  enabled_log { category = "AuditEvent" }
  metric { category = "AllMetrics" }
}

output "key_vault_uri" { value = azurerm_key_vault.this.vault_uri }
output "workload_identity_client_id" { value = azurerm_user_assigned_identity.workload.client_id }
output "app_insights_connection_string" {
  value     = azurerm_application_insights.this.connection_string
  sensitive = true
}
