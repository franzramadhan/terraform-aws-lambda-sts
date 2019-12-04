# Terraform AWS Lambda STS

This module will provision AWS Lambda function and AWS API Gateway to retrieve temporary STS credential from assumed-role ARN

It will be useful when we need to enable AWS resource access to services / entities running outside of AWS.

## Table of Content

- [Terraform AWS Lambda STS](#terraform-aws-lambda-sts)
  - [Table of Content](#table-of-content)
  - [Prerequisites](#prerequisites)
    - [Default](#default)
    - [Predefined URL](#predefined-url)
  - [Dependencies](#dependencies)
  - [Quick Start](#quick-start)
  - [Sample Payload](#sample-payload)
  - [Limitation](#limitation)
  - [Contributing](#contributing)
  - [Contributor](#contributor)
  - [License](#license)
  - [Acknowledgments](#acknowledgments)

## Prerequisites

### Default

- IAM Roles with required IAM policies.
- Configure [Trusted Relationship](https://aws.amazon.com/premiumsupport/knowledge-center/iam-assume-role-cli/) in assumed IAM Roles after lambda function provisioned

### Predefined URL

Aside of [default](#default) prerequisites, here are some additional resource to be provisioned prior this module usage:

- Route53 Zone for domain name
- Access to `us-east-1` aws region

## Dependencies

- [Terraform](https://releases.hashicorp.com/terraform/) version `0.11.x`.
- [awsudo](https://github.com/makethunder/awsudo) to assume role in AWS
- [Visual Studio Code](https://code.visualstudio.com/download) is the best editor for the [Terraform Extension](https://marketplace.visualstudio.com/items?itemName=mauve.terraform). After install activate auto format by go to`File`→`Preferences`→`Settings`. Choose`Text Editor`→`Formatting`and check`Format on Save`
- [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)

## Quick Start

- Install [dependencies](#dependencies)
- Execute `pre-commit install`
- Go to `examples` and go to each scenario
- Follow instruction in `README.md`

## Sample Payload

```
curl -X POST \
  https://<INVOKE URL of API Gateway> \
  -H 'Content-Type: application/json' \
  -d '{
	"assumed_role_arn" : "arn:aws:iam::743977200366:role/crossaccount/testing1/testing1-7142d92e739f6c6e",
	"token_duration" : 1800,
	"expiry_window" : 10
}'
```

`assumed_role_arn` is mandatory field. And should be filled with ARN of IAM role that you want to get credentials from.

If omitted, `token_duration` and `expiry_window` will have `3600` and `0` as default value.

## Limitation

[Session Duration Limit for Role chaining](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html)
```
Role chaining limits your AWS CLI or AWS API role session to a maximum of one hour. When you use the AssumeRole API operation to assume a role, you can specify the duration of your role session with the DurationSeconds parameter. You can specify a parameter value of up to 43200 seconds (12 hours), depending on the maximum session duration setting for your role. However, if you assume a role using role chaining and provide a DurationSeconds parameter value greater than one hour, the operation fails.
```

## Contributing

Check contribution guide in [CONTRIBUTING.md](https://github.com/traveloka/terraform-aws-lambda-sts/blob/master/CONTRIBUTING.md)

## Contributor

For question, issue, and pull request you can contact these people:

- [Frans Caisar Ramadhan](https://github.com/franzramadhan) (**Author**)

## License

See the [LICENSE](https://github.com/traveloka/terraform-aws-lambda-sts/blob/master/LICENSE)

## Acknowledgments

This repository was made possible by getting inspirations from below parties:

- [Readme Template](https://gist.github.com/PurpleBooth/109311bb0361f32d87a2)
- [Friendly Readme](https://rowanmanning.com/posts/writing-a-friendly-readme/)
- [Opensource Guide](https://opensource.guide/starting-a-project/)
- [Github Repository Template](https://github.com/traveloka/terraform-aws-modules-template)
- Inspiration from other open source projects
