output "url" {
  value = "${var.domain_name != "" ? join("", aws_api_gateway_domain_name.this.*.domain_name ) : aws_api_gateway_deployment.this.invoke_url}"
}

output "role_name" {
  value = "${module.lambda_role.role_name}"
}

output "role_arn" {
  value = "${module.lambda_role.role_arn}"
}
