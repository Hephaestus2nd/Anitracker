output "site_url" {
  description = "Public URL of the application."
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "Used by the deploy script to invalidate the cache."
  value       = aws_cloudfront_distribution.main.id
}

output "api_public_dns" {
  description = "API instance public DNS (port 8080 is reachable from CloudFront only)."
  value       = aws_eip.api.public_dns
}

output "rds_endpoint" {
  description = "RDS endpoint (private; reachable from the API instance only)."
  value       = aws_db_instance.main.endpoint
}

output "ssh_command" {
  description = "SSH into the API instance using the Learner Lab key."
  value       = "ssh -i labsuser.pem ubuntu@${aws_eip.api.public_dns}"
}

output "db_app_password" {
  description = "Password for app_user (terraform output -raw db_app_password)."
  value       = random_password.db_app.result
  sensitive   = true
}
