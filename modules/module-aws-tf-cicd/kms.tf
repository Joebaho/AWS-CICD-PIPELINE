# ── KMS Key For Pipeline Encryption ───────────────────────────

resource "aws_kms_key" "cicd" {
  description             = "KMS key for ${var.project_name} CI/CD resources"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableAccountLevelKMSAdministration"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "cicd" {
  name          = "alias/${var.project_name}-cicd"
  target_key_id = aws_kms_key.cicd.key_id
}
