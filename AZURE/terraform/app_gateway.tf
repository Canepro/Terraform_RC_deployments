# Public IP for Application Gateway
resource "azurerm_public_ip" "app_gateway" {
  name                = "${local.name}-app-gateway-pip"
  resource_group_name = local.resource_group.name
  location           = local.resource_group.location
  allocation_method   = "Static"
  sku                = "Standard"

  tags = local.common_tags
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = "${local.name}-app-gateway"
  resource_group_name = local.resource_group.name
  location           = local.resource_group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.app_gateway.id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appGatewayFrontendIP"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  backend_address_pool {
    name = "rocketchatBackendPool"
  }

  backend_address_pool {
    name = "grafanaBackendPool"
  }

  backend_http_settings {
    name                  = "rocketchatBackendSettings"
    cookie_based_affinity = "Disabled"
    port                  = 3000
    protocol              = "Http"
    request_timeout       = 60
    probe_name           = "rocketchatProbe"
    pick_host_name_from_backend_address = true
  }

  backend_http_settings {
    name                  = "grafanaBackendSettings"
    cookie_based_affinity = "Disabled"
    port                  = 3000
    protocol              = "Http"
    request_timeout       = 60
    probe_name           = "grafanaProbe"
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "httpListener"
    frontend_ip_configuration_name = "appGatewayFrontendIP"
    frontend_port_name            = "httpPort"
    protocol                      = "Http"
  }

  request_routing_rule {
    name                       = "mainRoutingRule"
    rule_type                  = "PathBasedRouting"
    http_listener_name         = "httpListener"
    url_path_map_name         = "mainPathMap"
    priority                   = 100
  }

  url_path_map {
    name                               = "mainPathMap"
    default_backend_address_pool_name  = "rocketchatBackendPool"
    default_backend_http_settings_name = "rocketchatBackendSettings"

    path_rule {
      name                       = "grafanaPathRule"
      paths                      = ["/grafana/*"]
      backend_address_pool_name  = "grafanaBackendPool"
      backend_http_settings_name = "grafanaBackendSettings"
    }
  }

  probe {
    name                = "rocketchatProbe"
    protocol            = "Http"
    path                = "/api/v1/info"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = true
  }

  probe {
    name                = "grafanaProbe"
    protocol            = "Http"
    path                = "/api/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = true
  }

  tags = local.common_tags
}
