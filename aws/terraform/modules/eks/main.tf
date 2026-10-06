module "eks" {
  source = "terraform-aws-modules/eks/aws"

  name               = "${var.project_name}-cluster-${var.environment}"
  version            = "~> 21.26"
  kubernetes_version = "1.36"

  vpc_id                 = var.vpc_id
  subnet_ids             = var.subnet_ids
  endpoint_public_access = true

  enable_irsa = true

  enable_cluster_creator_admin_permissions = true

  enabled_log_types = []

  compute_config = {
    enabled = false # disable EKS Auto Mode 
  }

  # Allow all traffic between nodes for pod-to-pod communication
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all traffic (pod-to-pod communication)"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  eks_managed_node_groups = {
    "${var.project_name}-server-${var.environment}" = {
      ami_type = "AL2023_x86_64_STANDARD"
      # ami_release_version = "1.34.2-20260107"
      min_size     = var.worker_node_min_size
      max_size     = var.worker_node_max_size
      desired_size = var.worker_node_desired_size

      instance_types = var.eks_instance_types

      disk_size = var.worker_node_disk_size

      labels = {
        workload    = "worker"
        environment = var.environment
      }

      tags = {
        Name = "${var.project_name}-worker-node-${var.environment}"
      }
    }
  }

  addons = {
    coredns = {
      resolve_conflicts_on_create = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      pod_identity_association = [{
        role_arn        = aws_iam_role.vpc_cni_role.arn
        service_account = "aws-node"
      }]
    }
    aws-ebs-csi-driver = {
      pod_identity_association = [{
        role_arn        = aws_iam_role.ebs_csi_role.arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }
}

# AWS Load Balancer Controller
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.24"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # AWS Load Balancer Controller
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait                   = true # Wait for LB Controller to be ready
    chart_version          = "3.6.0"
    role_name              = "${var.project_name}-${var.environment}-aws-lb-controller"
    role_name_use_prefix   = false
    policy_name            = "${var.project_name}-${var.environment}-aws-lb-controller"
    policy_name_use_prefix = false

    values = [yamlencode({
      topologySpreadConstraints = [{
        maxSkew           = 1
        topologyKey       = "topology.kubernetes.io/zone"
        whenUnsatisfiable = "DoNotSchedule"
        matchLabelKeys    = ["pod-template-hash"]
        labelSelector = {
          matchLabels = {
            "app.kubernetes.io/name" = "aws-load-balancer-controller"
          }
        }
      }]
    })]

    # Set VPC ID explicitly for load balancer controller
    set = [
      {
        name  = "vpcId"
        value = var.vpc_id
      },
      {
        name  = "serviceMutatorWebhookConfig.failurePolicy"
        value = "Ignore"
      }
    ]
  }
}
