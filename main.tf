terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~>1.12"
    }
  }
  required_version = ">=1.7.5"
}

locals {
  api_version = "2022-09-01"
  # Split the resource ID into parts
  parts = split("/", var.parent_resource_id)
  # Extract the resource type
  resource_type = join("/", slice(local.parts, 6, 8))
}

output "resource_type" {
  value = local.resource_type
}

# Retrieve the storage account details, including the private endpoint connections
data "azapi_resource" "private_endpoint_connection" {
  type                   = "${local.resource_type}@${local.api_version}"
  resource_id            = var.parent_resource_id
  response_export_values = ["properties.privateEndpointConnections"]
}

locals {
  private_endpoint_connections = {
    for connection in jsondecode(data.azapi_resource.private_endpoint_connection.output).properties.privateEndpointConnections : connection.name => connection
  }
}

# Approve the private endpoint
resource "azapi_update_resource" "connection_approval" {
  for_each  = local.private_endpoint_connections
  type      = "${local.resource_type}/privateEndpointConnections@${local.api_version}"
  name      = each.key
  parent_id = var.parent_resource_id

  body = jsonencode({
    properties = {
      privateLinkServiceConnectionState = {
        description = "Approved via Terraform"
        status      = "Approved"
      }
    }
  })
}
