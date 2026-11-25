variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "flashsale"
}

variable "kubernetes_version" {
  description = "A currently supported EKS version"
  type        = string
}

variable "github_repo" {
  description = "Your repo as USERNAME/REPO."
  type        = string
}

variable "node_instance_type" {
  type    = string
  default = "t3.large"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "api_allowed_cidrs" {
  description = "IP ranges allowed to reach the EKS API from the internet, for example [\"1.2.3.4/32\"] (your master's public IP)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
