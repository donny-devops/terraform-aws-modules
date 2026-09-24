# ─────────────────────────────────────────────────────────────────────────────
# AWS OIDC Identity Provider & Role for GitHub Actions (Zero Long-Lived Keys)
# ─────────────────────────────────────────────────────────────────────────────

data "tls_certificate" "github" {
  count = var.enable_github_oidc ? 1 : 0
  url   = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_oidc ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]

  tags = {
    Name = "github-actions-oidc"
  }
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  count = var.enable_github_oidc ? 1 : 0

  name                 = "github-actions-terraform-deployer"
  description          = "IAM Role assumed by GitHub Actions via OIDC to plan and apply Terraform infrastructure"
  assume_role_policy   = data.aws_iam_policy_document.github_oidc_assume_role[0].json
  max_session_duration = 3600

  tags = {
    Name = "github-actions-terraform-deployer"
  }
}

# Attach permissions needed to manage infrastructure
resource "aws_iam_role_policy_attachment" "github_actions_poweruser" {
  count = var.enable_github_oidc ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

output "github_actions_role_arn" {
  description = "The ARN of the IAM role for GitHub Actions to use as AWS_OIDC_ROLE_ARN in GitHub Secrets."
  value       = var.enable_github_oidc ? aws_iam_role.github_actions[0].arn : null
}
