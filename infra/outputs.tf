output "site_url" {
  description = "Public URL of the application."
  value       = "http://${aws_lb.main.dns_name}"
}

output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint (private; reachable from the API instance only)."
  value       = aws_db_instance.main.endpoint
}

output "db_app_password" {
  description = "Password for app_user (terraform output -raw db_app_password)."
  value       = random_password.db_app.result
  sensitive   = true
}
