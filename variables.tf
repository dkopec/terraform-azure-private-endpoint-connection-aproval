variable "parent_resource_id" {
  type        = string
  description = "The azure id of the resource that is being used for the private endpoint connection, this should be the origin/where you need to approve."
  validation {
    condition     = can(regex("^/subscriptions/[a-z0-9-]+/resourceGroups/[a-zA-Z0-9-]+/.+", var.parent_resource_id))
    error_message = "The Azure Resource ID must be in the correct format. E.g., /subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/{resource-provider}/{resource-type}/{resource-name}"
  }
}
