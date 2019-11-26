package testing

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

const awsRegion = "us-west-2"

func TestDefault(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/default",
		NoColor:      true,
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}
	// Make sure testing infrastructure removed at last
	defer terraform.Destroy(t, terraformOptions)
	// Do terraform init and terraform apply --auto-approve
	terraform.InitAndApply(t, terraformOptions)
}

func TestCustomDomain(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/custom-domain",
		NoColor:      true,
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}
	// Make sure testing infrastructure removed at last
	defer terraform.Destroy(t, terraformOptions)
	// Do terraform init and terraform apply --auto-approve
	terraform.InitAndApply(t, terraformOptions)
}
