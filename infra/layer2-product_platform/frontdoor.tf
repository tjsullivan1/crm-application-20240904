resource "azurerm_cdn_frontdoor_profile" "afd" {
  name                = "${var.base_name}-afd"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"

  response_timeout_seconds = 60
}

resource "azurerm_cdn_frontdoor_endpoint" "afd_endpoint" {
  name                     = "${var.base_name}-afd"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
}

resource "azurerm_cdn_frontdoor_origin_group" "default" {
  name                     = "default-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 0

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Http"
    interval_in_seconds = 100
  }
}

# This should move to Layer 3!
resource "azurerm_cdn_frontdoor_origin" "app01_01" {
  name                           = "default-origin"                 # TODO: change to "origin-app01-01"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.default.id
  enabled                        = true
  certificate_name_check_enabled = true

  host_name          = "crm-v1-l3-app001-01-app.azurewebsites.net"  # TODO: This should not be hardcoded
  http_port          = 80
  https_port         = 443
  origin_host_header = "crm-v1-l3-app001-01-app.azurewebsites.net"
  priority           = 1
  weight             = 1000
}

# // Routes
resource "azurerm_cdn_frontdoor_route" "route01_01" {
  name                          = "default-route"                 # TODO: change to "route-app01-01"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.afd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.default.id
  cdn_frontdoor_origin_ids      = [] //azurerm_cdn_frontdoor_origin.app01_01.id]
  cdn_frontdoor_rule_set_ids    = [] #azurerm_cdn_frontdoor_rule_set.example.id]
  
  enabled                = true
  https_redirect_enabled = true
  forwarding_protocol    = "MatchRequest"
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  # cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.contoso.id, azurerm_cdn_frontdoor_custom_domain.fabrikam.id]
  link_to_default_domain          = true

  /*
  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = ["account", "settings"]
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }*/
}

resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name                = replace("${var.base_name}-waf", "-", "")
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"
  mode                = "Detection"
  enabled             = true
}