# terraform-azure-private-endpoint-connection-aproval
A terraform module to automate the approval of private endpoint connections.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.7.5 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~>1.12 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | ~>1.12 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_update_resource.connection_approval](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) | resource |
| [azapi_resource.private_endpoint_connection](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_parent_resource_id"></a> [parent\_resource\_id](#input\_parent\_resource\_id) | The azure id of the resource that is being used for the private endpoint connection, this should be the origin/where you need to approve. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_type"></a> [resource\_type](#output\_resource\_type) | n/a |
<!-- END_TF_DOCS -->