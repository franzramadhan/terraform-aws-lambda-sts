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

module "role_crossaccount" {
  source            = "github.com/traveloka/terraform-aws-iam-role//modules/crossaccount?ref=v1.0.2"
  product_domain    = "dev"
  role_name         = "testing-crossaccount"
  environment       = "testing"
  role_path         = "/testing/"
  role_description  = "testing role for crossaccount access"
  service_name      = "test-lambda"
  trusted_role_arns = ["${module.this.role_arn}"]
}

resource "random_string" "external_id" {
  keepers = {
    api_gateway_url = "${module.this.url}"
  }

  length  = 32
  special = false
  upper   = true
}

module "role_external" {
  source           = "github.com/traveloka/terraform-aws-iam-role//modules/external?ref=v1.0.2"
  environment      = "testing"
  product_domain   = "dev"
  role_name        = "testing-external"
  role_description = "testing role for external access with external ID"
  account_id       = "${module.this.role_arn}"
  external_id      = "${random_string.external_id.result}"
}

output "assumed_role_arns" {
  value = "${list(module.role_crossaccount.role_arn, module.role_external.role_arn)}"
}
