provider "aws" {
  region = "us-east-2"
}

provider "tls" {}

module "eks_cluster" {
  source = "../../modules/services/eks-cluster"

  name         = "eks-cluster"
  min_size     = 1
  max_size     = 2
  desired_size = 1

  instance_types = ["t3.small"]
}

provider "kubernetes" {
  host = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(
    module.eks_cluster.cluster_certificate_authority[0].data
  )
  token = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
}

# module "simple_webapp" {
#   source = "../../modules/services/k8s-app"

#   name           = "simple-webapp"
#   image          = "paulbouwer/hello-kubernetes:1.10"
#   replicas       = 2
#   container_port = 8080

#   env_vars = {
#     PROVIDER = "Terraform"
#   }

#   depends_on = [module.eks_cluster]
# }
