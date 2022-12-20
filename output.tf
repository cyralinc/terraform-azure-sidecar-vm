output "sidecar_dns" {
  value       = local.sidecar_endpoint
  description = "Sidecar DNS endpoint"
}

# output "sidecar_load_balancer_dns" {
#   value       = aws_lb.cyral-lb.dns_name
#   description = "Sidecar load balancer DNS endpoint"
# }
