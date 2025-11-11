variable "cluster_name" {
  type    = string
  default = "kodi-eks-lab"
}

variable "cluster_version" {
  type    = number
  default = 1.33
}

variable "region" {
  type    = string
  default = "ap-southeast-1"

}

variable "availability_zones" {
  type    = list(any)
  default = ["ap-southeast-1a", "ap-southeast-1b"]
}



variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))

  default = [
    {
      name    = "kube-proxy"
      version = "v1.25.6-eksbuild.1"
    },
    {
      name    = "vpc-cni"
      version = "v1.12.2-eksbuild.1"
    },
    {
      name    = "coredns"
      version = "v1.9.3-eksbuild.2"
    },
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.23.0-eksbuild.1"
    }
  ]
}
