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

# External Secrets Operator IAM Role (EKS Pod Identity)
resource "aws_iam_role" "external_secrets_role" {
  name = "${var.project_name}-external-secrets-role-${var.environment}"

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
    Name = "${var.project_name}-external-secrets-role-${var.environment}"
  }
}

# Bind the role to the External Secrets service account (namespace external-secrets)
resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.external_secrets_role.arn
}

# IAM policy for accessing secrets
resource "aws_iam_policy" "external_secrets_policy" {
  name        = "${var.project_name}-external-secrets-policy-${var.environment}"
  description = "Policy for External Secrets Operator to read AWS SSM Parameter Store and Secrets Manager"

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
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets",
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
