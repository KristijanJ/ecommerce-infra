# VPC CNI IAM Role
resource "aws_iam_role" "vpc_cni_role" {
  name = "${var.project_name}-vpc-cni-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Principal = {
          "Service" : ["pods.eks.amazonaws.com"]
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-vpc-cni-role-${var.environment}"
  }
}

# Attach AWS managed policy for VPC CNI
resource "aws_iam_role_policy_attachment" "vpc_cni_policy" {
  role       = aws_iam_role.vpc_cni_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# EBS CSI IAM Role
resource "aws_iam_role" "ebs_csi_role" {
  name = "${var.project_name}-ebs-csi-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Principal = {
          "Service" : ["pods.eks.amazonaws.com"]
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ebs-csi-role-${var.environment}"
  }
}

# Attach AWS managed policy for EBS CSI
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
}

resource "aws_iam_role" "external_secrets_role" {
  name = "${var.project_name}-external-secrets-role-${var.environment}"
  # name_prefix = module.eks.oidc_provider_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:external-secrets:external-secrets"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-external-secrets-role-${var.environment}"
  }
}

# IAM policy for accessing secrets
resource "aws_iam_policy" "external_secrets_policy" {
  name        = "${var.project_name}-external-secrets-policy-${var.environment}"
  description = "Policy for External Secrets Operator to access AWS SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:DescribeParameters",
        ]
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets_policy" {
  role       = aws_iam_role.external_secrets_role.name
  policy_arn = aws_iam_policy.external_secrets_policy.arn
}
