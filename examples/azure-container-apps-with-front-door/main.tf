locals {
  orginization     = try(var.orginization, random_pet.pet.id)
  environment      = var.environment
  name_seperator   = var.name_seperator
  name             = [local.orginization, local.environment, substr(random_id.id.hex, 0, 4)]
  custom_subdomain = "test"
}

resource "random_pet" "pet" {
  length = 1
}

resource "random_id" "id" {
  byte_length = 8
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "aca" {
  name     = join(local.name_seperator, concat(["rg", "aca"], local.name))
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "vnet" {
  name                = join(local.name_seperator, concat(["vnet"], local.name))
  location            = azurerm_resource_group.aca.location
  resource_group_name = azurerm_resource_group.aca.name
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "private_link_service" {
  name                                          = join(local.name_seperator, concat(["snet", "pls"], local.name))
  resource_group_name                           = azurerm_resource_group.aca.name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = [cidrsubnet(var.address_space, 8, 1)]
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "aca" {
  name                 = join(local.name_seperator, concat(["snet", "aca"], local.name))
  resource_group_name  = azurerm_resource_group.aca.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space, 7, 2)]
}

resource "azurerm_log_analytics_workspace" "loganalytics" {
  name                = join(local.name_seperator, concat(["law"], local.name))
  location            = azurerm_resource_group.aca.location
  resource_group_name = azurerm_resource_group.aca.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appinsights" {
  name                = join(local.name_seperator, concat(["app-insights"], local.name))
  location            = azurerm_resource_group.aca.location
  resource_group_name = azurerm_resource_group.aca.name
  workspace_id        = azurerm_log_analytics_workspace.loganalytics.id
  application_type    = "web"
}

resource "azurerm_container_registry" "acr" {
  name                = replace(join(local.name_seperator, concat(["acr"], local.name)), "/[^A-Za-z0-9]/", "") # Remove non alphanumeric characters
  sku                 = "Standard"
  location            = azurerm_resource_group.aca.location
  resource_group_name = azurerm_resource_group.aca.name
}

resource "azurerm_container_app_environment" "containerappenv" {
  name                           = join(local.name_seperator, concat(["cae"], local.name))
  location                       = azurerm_resource_group.aca.location
  resource_group_name            = azurerm_resource_group.aca.name
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.loganalytics.id
  infrastructure_subnet_id       = azurerm_subnet.aca.id
  internal_load_balancer_enabled = true
}

resource "azurerm_user_assigned_identity" "containerapp" {
  name                = join(local.name_seperator, concat(["uai", "aca"], local.name))
  location            = azurerm_resource_group.aca.location
  resource_group_name = azurerm_resource_group.aca.name
}

resource "azurerm_role_assignment" "containerapp" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "acrpull"
  principal_id         = azurerm_user_assigned_identity.containerapp.principal_id
  depends_on = [
    azurerm_user_assigned_identity.containerapp
  ]
}

resource "azurerm_container_app" "containerapp-api1" {
  name                         = join(local.name_seperator, concat(["ca", "ap1"], local.name))
  container_app_environment_id = azurerm_container_app_environment.containerappenv.id
  resource_group_name          = azurerm_resource_group.aca.name
  revision_mode                = "Multiple"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.containerapp.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.containerapp.id
  }

  ingress {
    external_enabled = false
    target_port      = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    container {
      name   = "helloworldcontainerapp"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

}

resource "azurerm_container_app" "containerapp-api2" {
  name                         = join(local.name_seperator, concat(["ca", "ap2"], local.name))
  container_app_environment_id = azurerm_container_app_environment.containerappenv.id
  resource_group_name          = azurerm_resource_group.aca.name
  revision_mode                = "Multiple"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.containerapp.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.containerapp.id
  }

  ingress {
    external_enabled = false
    target_port      = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    container {
      name   = "helloworldcontainerapp"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

}

resource "azurerm_container_app" "containerapp-ui" {
  name                         = join(local.name_seperator, concat(["ca", "ui"], local.name))
  container_app_environment_id = azurerm_container_app_environment.containerappenv.id
  resource_group_name          = azurerm_resource_group.aca.name
  revision_mode                = "Multiple"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.containerapp.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.containerapp.id
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    container {
      name   = "helloworldcontainerapp"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name  = "API1_URL"
        value = azurerm_container_app.containerapp-api1.ingress[0].fqdn
      }
      env {
        name  = "API2_URL"
        value = azurerm_container_app.containerapp-api2.ingress[0].fqdn
      }

      readiness_probe {
        transport = "HTTP"
        port      = 80
      }

      liveness_probe {
        transport = "HTTP"
        port      = 80
      }

      startup_probe {
        transport = "HTTP"
        port      = 80
      }
    }
  }

}

#region private link service
data "azurerm_lb" "kubernetes-internal" {
  name                = "kubernetes-internal"
  resource_group_name = format("MC_%s-rg_%s_%s", split(".", azurerm_container_app.containerapp-ui.ingress[0].fqdn)[1], split(".", azurerm_container_app.containerapp-ui.ingress[0].fqdn)[1], azurerm_resource_group.aca.location)
}
resource "azurerm_private_link_service" "pls" {
  name                = join(local.name_seperator, concat(["pls", "aca"], local.name))
  resource_group_name = azurerm_resource_group.aca.name
  location            = azurerm_resource_group.aca.location

  visibility_subscription_ids                 = [data.azurerm_client_config.current.subscription_id]
  load_balancer_frontend_ip_configuration_ids = [data.azurerm_lb.kubernetes-internal.frontend_ip_configuration.0.id]
  auto_approval_subscription_ids              = [data.azurerm_client_config.current.subscription_id]

  nat_ip_configuration {
    name                       = "primary"
    private_ip_address_version = "IPv4"
    subnet_id                  = azurerm_subnet.private_link_service.id
    primary                    = true
  }
}
#endregion

#region front door service
resource "azurerm_cdn_frontdoor_profile" "fd-profile" {
  depends_on = [azurerm_private_link_service.pls]

  name                = join(local.name_seperator, concat(["fdprofile", "aca"], local.name))
  resource_group_name = azurerm_resource_group.aca.name
  sku_name            = "Premium_AzureFrontDoor"
}
resource "azurerm_cdn_frontdoor_endpoint" "fd-endpoint" {
  name                     = join(local.name_seperator, concat(["fdendpoint", "aca"], local.name))
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd-profile.id
}
resource "azurerm_cdn_frontdoor_origin_group" "fd-origin-group" {
  name                     = join(local.name_seperator, concat(["fdorigingroup", "aca"], local.name))
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd-profile.id

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
  }
}
resource "azurerm_cdn_frontdoor_route" "fd-route" {
  name                          = join(local.name_seperator, concat(["fdroute", "aca"], local.name))
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd-endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.fd-origin-group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.fd-origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.my_custom_domain.id]
  link_to_default_domain          = false
}

resource "azurerm_cdn_frontdoor_origin" "fd-origin" {
  name                           = join(local.name_seperator, concat(["fdorigin", "aca"], local.name))
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.fd-origin-group.id
  enabled                        = true
  host_name                      = azurerm_container_app.containerapp-ui.ingress[0].fqdn
  origin_host_header             = azurerm_container_app.containerapp-ui.ingress[0].fqdn
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  private_link {
    request_message        = "Request access for Private Link Origin CDN Frontdoor"
    location               = azurerm_resource_group.aca.location
    private_link_target_id = azurerm_private_link_service.pls.id
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "my_custom_domain" {
  name      = join(local.name_seperator, ["fdcd", local.custom_subdomain, replace(data.azurerm_dns_zone.parent.name, ".", local.name_seperator)])
  host_name = join(".", [local.custom_subdomain, data.azurerm_dns_zone.parent.name])

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd-profile.id
  dns_zone_id              = data.azurerm_dns_zone.parent.id

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }

}

# Terraform creation of these is required see: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain
resource "azurerm_dns_txt_record" "validation" {
  name                = join(".", ["_dnsauth", local.custom_subdomain])
  zone_name           = data.azurerm_dns_zone.parent.name
  resource_group_name = data.azurerm_dns_zone.parent.resource_group_name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.my_custom_domain.validation_token
  }
}

resource "azurerm_dns_cname_record" "forwarding" {
  depends_on = [azurerm_cdn_frontdoor_route.fd-route, azurerm_cdn_frontdoor_security_policy.my_security_policy]

  name                = local.custom_subdomain
  zone_name           = data.azurerm_dns_zone.parent.name
  resource_group_name = data.azurerm_dns_zone.parent.resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.fd-endpoint.host_name
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "my_custom_domain_association" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.my_custom_domain.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.fd-route.id]
}

resource "azurerm_cdn_frontdoor_security_policy" "my_security_policy" {
  name                     = join(local.name_seperator, concat(["fd", "security", "policy", "aca"], local.name))
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd-profile.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.my_waf_policy.id

      association {
        patterns_to_match = ["/*"]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.my_custom_domain.id
        }
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "my_waf_policy" {
  name                = join("", concat(["fd", "waf", "policy", "aca"], local.name))
  resource_group_name = azurerm_cdn_frontdoor_profile.fd-profile.resource_group_name
  sku_name            = azurerm_cdn_frontdoor_profile.fd-profile.sku_name
  enabled             = true
  mode                = var.waf_mode

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }
}
#endregion

module "aca_aproval" {
  source             = "./modules/private_endpoint_connection_aproval"
  parent_resource_id = azurerm_private_link_service.pls.id
}