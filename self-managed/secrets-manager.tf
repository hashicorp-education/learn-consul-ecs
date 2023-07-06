##Bootstrap Token
resource "random_uuid" "bootstrap_token" {
  #count = var.acls ? 1 : 0
}

resource "aws_secretsmanager_secret" "bootstrap_token" {
  #count = var.acls ? 1 : 0
  name                    = "${local.name}-bootstrap-token"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "bootstrap_token" {
  #count         = var.acls ? 1 : 0
  secret_id     = aws_secretsmanager_secret.bootstrap_token.id
  secret_string = random_uuid.bootstrap_token.result
}


data "aws_secretsmanager_secret_version" "bootstrap_token" {
  secret_id = aws_secretsmanager_secret.bootstrap_token.id
  depends_on = [aws_secretsmanager_secret_version.bootstrap_token]
}

## CA Certificate
resource "tls_private_key" "ca" {
  #count       = var.tls ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "ca" {
  #count           = var.tls ? 1 : 0
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "Consul Agent CA"
    organization = "HashiCorp Inc."
  }

  // 5 years.
  validity_period_hours = 43800

  is_ca_certificate  = true
  set_subject_key_id = true

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]

}

resource "aws_secretsmanager_secret" "ca_key" {
  #count = var.tls ? 1 : 0
  name = "${local.name}-ca-key-8"
}

resource "aws_secretsmanager_secret_version" "ca_key" {
  #count         = var.tls ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ca_key.id
  secret_string = tls_private_key.ca.private_key_pem
}


data "aws_secretsmanager_secret_version" "ca_key" {
  secret_id = aws_secretsmanager_secret.ca_key.id
  depends_on = [aws_secretsmanager_secret_version.ca_key]
}


resource "aws_secretsmanager_secret" "ca_cert" {
  #count = var.tls ? 1 : 0
  name = "${local.name}-ca-cert-8"
}

resource "aws_secretsmanager_secret_version" "ca_cert" {
  #count         = var.tls ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ca_cert.id
  secret_string = tls_self_signed_cert.ca.cert_pem
}

data "aws_secretsmanager_secret_version" "ca_cert" {
  secret_id = aws_secretsmanager_secret.ca_cert.id
  depends_on = [aws_secretsmanager_secret_version.ca_cert]
}


## Server cert

resource "tls_private_key" "server_ca" {
  #count       = var.tls ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "server_ca" {
  #count           = var.tls ? 1 : 0
  private_key_pem = tls_private_key.server_ca.private_key_pem

  subject {
    common_name  = "server.dc1.consul"
    organization = "HashiCorp Inc."
  }

  // 5 years.
  validity_period_hours = 43800

  is_ca_certificate  = false
  set_subject_key_id = true

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
    "key_encipherment",
    "client_auth",
    "server_auth"
  ]

  dns_names = [
   "*.elb.amazonaws.com",
   "*.amazonaws.com",
   "consul-server", 
   "*.consul-server", 
   "*.consul-server.consul", 
   "consul-server.consul", 
   "*.consul-server.consul.svc", 
   "consul-server.consul.svc", 
   "*.server.dc1.consul", 
   "server.dc1.consul", 
   "localhost"
  ]

}

resource "aws_secretsmanager_secret" "server_key" {
  #count = var.tls ? 1 : 0
  name = "${local.name}-server-key-8"
}

resource "aws_secretsmanager_secret_version" "server_key" {
  #count         = var.tls ? 1 : 0
  secret_id     = aws_secretsmanager_secret.server_key.id
  secret_string = tls_private_key.server_ca.private_key_pem
}

data "aws_secretsmanager_secret_version" "server_key" {
  secret_id = aws_secretsmanager_secret.server_key.id
  depends_on = [aws_secretsmanager_secret_version.server_key]
}

resource "aws_secretsmanager_secret" "server_cert" {
  #count = var.tls ? 1 : 0
  name = "${local.name}-server-cert-8"
}

resource "aws_secretsmanager_secret_version" "server_cert" {
  #count         = var.tls ? 1 : 0
  secret_id     = aws_secretsmanager_secret.server_cert.id
  secret_string = tls_self_signed_cert.server_ca.cert_pem
}

data "aws_secretsmanager_secret_version" "server_cert" {
  secret_id = aws_secretsmanager_secret.server_cert.id
  depends_on = [aws_secretsmanager_secret_version.server_cert]
}