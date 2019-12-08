# CHANGELOG

## v0.3.0 (Dec 08, 2019)

NOTES:

* Updated JSON response format
* Updated README

ENHANCEMENTS:

* Updated code to have generic JSON response to comply with [Sourcing Credentials with an External Process](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html)
* Enhanced logging format
* Improved error handling

## v0.2.1 (Dec 05, 2019)

NOTES:

* Fix bug for wrong units of `expiry_window`
* Updated examples
* Updated README

BUG FIXES:

* Fix `expiry_window` unit to second
* Adjust generated json response

## v0.2.0 (Dec 04, 2019)

NOTES:

* Added features and improvement
* Updated examples
* Updated README
* Added and removed some variables

FEATURES:

* Make `assumed_role_arn` as input variable from HTTP request. So it can assume to multiple role
* Added custom `token_duration` as HTTP request
* Use `aws_api_gateway_usage_plan` to have better control of API usage

## v0.1.0 (Nov 26, 2019)

NOTES:

* Initial commit
* Added examples
* Added test scenario

FEATURES:

* AWS Lambda function to retrieve STS credential from assumed-role
* AWS API Gateway with source IP whitelisting
* Enable custom domain for API Gateway URL and automated ACM creation
