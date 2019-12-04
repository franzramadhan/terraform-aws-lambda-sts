provider "aws" {
  version = "~> 2.0"
  region  = "us-west-2"
}

module "this" {
  source         = "../../"
  environment    = "testing"
  description    = "Testing lambda creation"
  product_domain = "dev"
  service_name   = "test-lambda"

  allowed_cidr = [
    "10.32.0.0/16",
  ]
}

output "url" {
  value = "${module.this.url}"
}

module "assumed_role1" {
  source            = "github.com/traveloka/terraform-aws-iam-role//modules/crossaccount?ref=v1.0.2"
  product_domain    = "dev"
  role_name         = "testing1"
  environment       = "testing"
  role_path         = "/testing1/"
  role_description  = "testing role"
  service_name      = "test-lambda1"
  trusted_role_arns = ["${module.this.role_arn}"]
}

module "assumed_role2" {
  source            = "github.com/traveloka/terraform-aws-iam-role//modules/crossaccount?ref=v1.0.2"
  product_domain    = "dev"
  role_name         = "testing2"
  environment       = "testing"
  role_path         = "/testing2/"
  role_description  = "testing role"
  service_name      = "test-lambda2"
  trusted_role_arns = ["${module.this.role_arn}"]
}

output "assumed_role_arns" {
  value = "${list(module.assumed_role1.role_arn, module.assumed_role2.role_arn)}"
}
