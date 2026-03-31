data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [ module.eks ]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [ module.eks ]
}

data "aws_region" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  #version = "19.21.0"
  #version = "21.15.1"
  version = "~> 21.0"

  name = local.name
  kubernetes_version = "1.35"
  endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  endpoint_private_access = true
  
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "system"]
  }

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.public_subnets
  #control_plane_subnet_ids       = module.vpc.private_subnets 

  addons = {
    aws-ebs-csi-driver = {
      #service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      service_account_role_arn =  module.ebs_csi_driver_irsa.arn
    }
    coredns            = {}
    kube-proxy         = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    vpc-cni            = {
      before_compute = true
    }
  }

  # Needed by the aws-ebs-csi-driver
  iam_role_additional_policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }

  eks_managed_node_groups = {
    consul = {
      name = "consul"
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]
      #instance_types = ["t3a.medium"]
      use_custom_launch_template = false

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
      }

      min_size     = 1
      max_size     = 5
      desired_size = 3
      iam_role_attach_cni_policy = true
      tags = {
        "kubernetes.io/cluster/${local.name}" = "owned"
        "kubernetes.io/role/worker"            = 1
      }
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_cluster_all = {
      description                   = "Cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_consul = {
      description = "Ingress to Consul ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = ["10.0.0.0/16"]
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.4.0"
  
  name = "${module.eks.cluster_name}-ebs-csi-driver-"
  attach_ebs_csi_policy = true

  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  /*
  version = "~> 5.20"

  # create_role      = false
  role_name_prefix = "${module.eks.cluster_name}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
  */
}

# VPC CNI Add-on
#resource "aws_eks_addon" "vpc_cni" {
#  cluster_name = local.name
#  addon_name   = "vpc-cni"
#  depends_on = [
#    module.eks
#  ]
#  tags = {
#    Name = "vpc-cni"
#  }
#}

# CoreDNS Add-on
#resource "aws_eks_addon" "coredns" {
#  cluster_name = local.name
#  addon_name   = "coredns"
#  depends_on = [
#    module.eks
#  ]
#  tags = {
#    Name = "coredns"
#  }
#}

# kube-proxy Add-on
#resource "aws_eks_addon" "kube_proxy" {
#  cluster_name = local.name
#  addon_name   = "kube-proxy"
#  depends_on = [
#    module.eks
#  ]
#  tags = {
#    Name = "kube-proxy"
#  }
#}

#resource "aws_eks_addon" "ebs_csi" {
#  cluster_name = local.name
#  addon_name   = "aws-ebs-csi-driver"
#  addon_version            = "v1.57.1-eksbuild.1"
#  configuration_values = jsonencode({
#    replicaCount = 4
#    resources = {
#      limits = {
#        cpu    = "100m"
#        memory = "150Mi"
#      }
#      requests = {
#        cpu    = "100m"
#        memory = "150Mi"
#      }
#    }
#  })
#
#  depends_on = [
#    module.eks
#  ]
#  tags = {
#    Name = "aws-ebs-csi-driver"
#  }
#}

// ### New

# EKS addon
#resource "aws_eks_addon" "ebs_csi_driver" {
#  cluster_name             = module.eks.cluster_name
#  addon_name               = "aws-ebs-csi-driver"
#  addon_version            = "v1.57.1-eksbuild.1"
#  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
#}

# IAM
#resource "aws_iam_role" "ebs_csi_driver" {
#  name               = "ebs-csi-driver"
#  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json
#}

#data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
#  statement {
#    effect = "Allow"
#  
#    principals {
#      type        = "Federated"
#      #identifiers = [aws_iam_openid_connect_provider.eks.arn]
#      identifiers = module.eks.oidc_provider_arn
#    }
#
#    actions = [
#      "sts:AssumeRoleWithWebIdentity",
#    ]
#
#    condition {
#      test     = "StringEquals"
#      #variable = "${aws_iam_openid_connect_provider.eks.url}:aud"
#      variable = "${module.eks.oidc_provider}:aud"
#      values   = ["sts.amazonaws.com"]
#    }
#
#    condition {
#      test     = "StringEquals"
#      #variable = "${aws_iam_openid_connect_provider.eks.url}:sub"
#      variable = "${module.eks.oidc_provider}:sub"
#      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
#    }
#
#  }
#}
#
#resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
#  role       = aws_iam_role.ebs_csi_driver.name
#}