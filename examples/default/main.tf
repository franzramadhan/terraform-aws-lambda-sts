provider "aws" {
  version = "~> 2.0"
  region  = "us-west-2"
}

module "this" {
  source           = "../../"
  environment      = "testing"
  description      = "Testing lambda creation"
  product_domain   = "dev"
  service_name     = "test-lambda"
  assumed_role_arn = "arn:aws:iam::12345678:role/ReadOnly"

  allowed_cidr = [
    "139.0.104.0/28",
  ]
}

output "url" {
  value = "${module.this.url}"
}

output "role_arn" {
  value = "${module.this.role_arn}"
}
