variable "address_space" {
  type    = string
  default = "10.0.0.0/16"
}

variable "orginization" {
  type = string
}

variable "environment" {
  type = string
  default = "example"
}

variable "name_seperator" {
  type = string
  default = "-"
}

variable "waf_mode" {
  type        = string
  default     = "Prevention"
  description = "The Front Door Firewall Policy mode."
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "Must be either Detection or Prevention."
  }
}

variable "resource_group_location" {
  type        = string
  description = "Location for all resources."
  default     = "canadacentral"
}