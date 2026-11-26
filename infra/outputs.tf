output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "github_actions_role_arn" {
  description = "paste this into the AWS_ROLE_ARN repo variable"
  value       = aws_iam_role.github_actions.arn
}

output "update_kubeconfig" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}
