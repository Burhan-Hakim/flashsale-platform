variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "flashsale"
}

variable "kubernetes_version" {
  description = "EKS version, pick one"
  type        = string
}

variable "github_repo" {
  description = "github repo as user/repo"
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
  description = "who can reach the EKS API from the internet, set it to the master IP with /32"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
