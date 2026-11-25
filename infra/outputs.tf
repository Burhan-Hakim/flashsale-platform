output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "github_actions_role_arn" {
  description = "Goes into the GitHub variable AWS_ROLE_ARN."
  value       = aws_iam_role.github_actions.arn
}

output "update_kubeconfig" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
