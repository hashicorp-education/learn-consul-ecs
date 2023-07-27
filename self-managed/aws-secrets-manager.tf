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