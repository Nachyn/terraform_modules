## Данные: получаем VPC по умолчанию для построения конфигурации сети
data "aws_vpc" "default" {
  default = true
}

## Данные: получаем список подсетей в найденном VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

## IAM: роль control plane (EKS) — роль, используемая самим кластером
resource "aws_iam_role" "cluster" {
  name               = "${var.name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
}

## IAM Policy Document: доверительная политика для роли control plane
data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

## Присоединение управляемой политики AmazonEKSClusterPolicy к роли control plane
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

## Ресурс: сам кластер EKS — создание control plane
resource "aws_eks_cluster" "cluster" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = "1.34"

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]
}

## ------------------------------------------------------------
## EBS CSI (драйвер для работы с EBS томами в кластере)
## ------------------------------------------------------------

## Данные: получаем сертификат TLS OIDC-issuer для thumbprint'а провайдера
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  depends_on = [aws_eks_cluster.cluster]
}

## Ресурс: провайдер OIDC для кластера — необходим для сервисных аккаунтов с IRSA
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

## IAM: роль для EBS CSI драйвера — роль, которой будет пользоваться сервисный аккаунт
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json
}

## IAM Policy Document: доверительная политика для роли EBS CSI (IRSA)
data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.eks.url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.eks.url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

  }
}

## Присоединение управляющей политики к роли EBS CSI (разрешает работу с EBS)
resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

## ------------------------------------------------------------
## Node group: IAM для рабочих узлов (EC2) и их политики
## ------------------------------------------------------------

## IAM: роль для нод-группы (EC2) — роль, назначаемая узлам кластера
resource "aws_iam_role" "node_group" {
  name               = "${var.name}-node-group"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
}

## IAM Policy Document: доверительная политика для роли нод (EC2 assume)
data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

## Присоединение базовых управляемых политик к роли нод
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

## Ресурс: нод-группа EKS — указывает типы инстансов и масштабирование
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = var.name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = data.aws_subnets.default.ids
  instance_types  = var.instance_types

  scaling_config {
    min_size     = var.min_size
    max_size     = var.max_size
    desired_size = var.desired_size
  }

  # Разрешения для роли IAM должны определяться до запуска и после остановки
  # группы узлов EKS. В противном случае EKS не сможет правильно удалить
  # серверы EC2 и сетевые интерфейсы Elastic.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
  ]
}

## Дополнительный компонент: EBS CSI как addon — устанавливается после наличия нод
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.29.1-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [
    aws_eks_node_group.nodes,
    aws_iam_role.ebs_csi_driver,
    aws_iam_openid_connect_provider.eks
  ]
}
