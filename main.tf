terraform {
  required_version = ">= 0.11.14, < 0.12.0"
}

module "resource_naming" {
  source        = "github.com/traveloka/terraform-aws-resource-naming?ref=v0.17.1"
  name_prefix   = "${var.service_name}"
  resource_type = "lambda_function"
}

module "lambda_role" {
  source                    = "github.com/traveloka/terraform-aws-iam-role//modules/lambda?ref=v1.0.2"
  product_domain            = "${var.product_domain}"
  service_name              = "${var.service_name}"
  descriptive_name          = "${var.description}"
  environment               = "${var.environment}"
  role_max_session_duration = "${var.role_max_session_duration}"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${module.resource_naming.name}"
  role   = "${module.lambda_role.role_name}"
  policy = "${data.aws_iam_policy_document.lambda_policy.json}"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${module.resource_naming.name}"
  retention_in_days = 14

  tags {
    Service       = "${var.service_name}"
    ProductDomain = "${var.product_domain}"
    Description   = "Cloudwatch Log for ${var.service_name}"
    Environment   = "${var.environment}"
    ManagedBy     = "terraform"
  }
}

resource "aws_lambda_function" "this" {
  function_name    = "${module.resource_naming.name}"
  filename         = "${path.module}/build/main.zip"
  handler          = "main"
  source_code_hash = "${data.archive_file.lambda.output_base64sha256}"
  role             = "${module.lambda_role.role_arn}"
  runtime          = "go1.x"
  memory_size      = 128

  environment {
    variables = {
      ASSUMED_ROLE_ARN = "${var.assumed_role_arn}"
    }
  }

  tags {
    Service       = "${var.service_name}"
    ProductDomain = "${var.product_domain}"
    Description   = "Lambda Function for ${var.service_name}"
    Environment   = "${var.environment}"
    ManagedBy     = "terraform"
  }
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.this.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*/*"
}

resource "aws_api_gateway_resource" "this" {
  rest_api_id = "${aws_api_gateway_rest_api.this.id}"
  parent_id   = "${aws_api_gateway_rest_api.this.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_rest_api" "this" {
  name   = "this"
  policy = "${data.aws_iam_policy_document.acl.json}"

  tags {
    Service       = "${var.service_name}"
    ProductDomain = "${var.product_domain}"
    Description   = "API Gateway for ${var.service_name}"
    Environment   = "${var.environment}"
    ManagedBy     = "terraform"
  }
}

resource "aws_api_gateway_method" "this" {
  rest_api_id   = "${aws_api_gateway_rest_api.this.id}"
  resource_id   = "${aws_api_gateway_resource.this.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = "${aws_api_gateway_rest_api.this.id}"
  resource_id             = "${aws_api_gateway_resource.this.id}"
  http_method             = "${aws_api_gateway_method.this.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.this.invoke_arn}"
}

resource "aws_api_gateway_method" "root" {
  rest_api_id   = "${aws_api_gateway_rest_api.this.id}"
  resource_id   = "${aws_api_gateway_rest_api.this.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id = "${aws_api_gateway_rest_api.this.id}"
  resource_id = "${aws_api_gateway_method.root.resource_id}"
  http_method = "${aws_api_gateway_method.root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.this.invoke_arn}"
}

resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    "aws_api_gateway_integration.this",
    "aws_api_gateway_integration.root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.this.id}"
  stage_name  = "v1"
}

resource "null_resource" "build" {
  triggers {
    uuid = "${uuid()}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/build && GOARCH=amd64 GOOS=linux go build -ldflags='-w -s' -o ${path.module}/build/main ${path.module}/code/main.go"
  }
}

resource "aws_api_gateway_domain_name" "this" {
  count           = "${ var.domain_name != "" ? 1 : 0 }"
  certificate_arn = "${aws_acm_certificate.cert.arn}"
  domain_name     = "${var.service_name}.${var.domain_name}"
}

resource "aws_route53_record" "this" {
  count   = "${ var.domain_name != "" ? 1 : 0 }"
  name    = "${aws_api_gateway_domain_name.this.domain_name}"
  type    = "A"
  zone_id = "${data.aws_route53_zone.public.id}"

  alias {
    evaluate_target_health = true
    name                   = "${aws_api_gateway_domain_name.this.cloudfront_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.this.cloudfront_zone_id}"
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cert" {
  count                     = "${ var.domain_name != "" ? 1 : 0 }"
  provider                  = "aws.us-east-1"
  domain_name               = "${var.domain_name}"
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name          = "${var.domain_name}"
    ProductDomain = "${var.product_domain}"
    Environment   = "${var.environment}"
    Description   = "Certificate for ${var.domain_name} and its wildcard"
    ManagedBy     = "terraform"
  }
}

resource "aws_route53_record" "cert_validation" {
  count    = "${ var.domain_name != "" ? 1 : 0 }"
  provider = "aws.us-east-1"
  name     = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type     = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id  = "${data.aws_route53_zone.public.id}"
  records  = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = "${ var.domain_name != "" ? 1 : 0 }"
  provider                = "aws.us-east-1"
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
