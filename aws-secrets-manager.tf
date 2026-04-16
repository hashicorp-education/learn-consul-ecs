##Bootstrap Token
resource "random_uuid" "bootstrap_token" {
}

resource "aws_secretsmanager_secret" "bootstrap_token" {
  name                    = "${local.name}-bootstrap-token"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "bootstrap_token" {
  secret_id     = aws_secretsmanager_secret.bootstrap_token.id
  secret_string = random_uuid.bootstrap_token.result
}

data "aws_secretsmanager_secret_version" "bootstrap_token" {
  secret_id  = aws_secretsmanager_secret.bootstrap_token.id
  depends_on = [aws_secretsmanager_secret_version.bootstrap_token]
}