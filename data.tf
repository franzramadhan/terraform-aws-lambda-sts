data "aws_route53_zone" "public" {
  count        = "${ var.domain_name != "" ? 1 : 0 }"
  name         = "${var.domain_name}."
  private_zone = "false"
}

data "archive_file" "lambda" {
  depends_on  = ["null_resource.build"]
  type        = "zip"
  source_file = "${path.module}/build/main"
  output_path = "${path.module}/build/main.zip"
}

data "aws_iam_policy_document" "acl" {
  statement {
    sid       = "1"
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["execute-api:/*/*/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "2"
    effect    = "Deny"
    actions   = ["execute-api:Invoke"]
    resources = ["execute-api:/*/*/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"

      values = ["${var.allowed_cidr}"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.this.arn}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "${var.assumed_role_arn}",
    ]
  }
}
