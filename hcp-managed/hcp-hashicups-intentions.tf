resource "consul_config_entry" "service_intentions_deny_by_default" {
  name = "*"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "*"
        Action = "deny"
      }
    ]
  })
}

resource "consul_config_entry" "service_intentions_public_api_to_product_api" {
  name = "product-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "public-api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_product_api_to_product_db" {
  name = "product-db"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "product-api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_public_api_to_payments" {
  name = "payments"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "public-api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_nginx_to_public_api" {
  name = "public-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "nginx"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_api_gateway_to_nginx" {
  name = "nginx"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "api-gateway"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_nginx_to_frontend" {
  name = "frontend"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "nginx"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}