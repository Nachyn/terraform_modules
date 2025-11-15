package test

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/random"

	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestHelloWorldAppExample(t *testing.T) {

	t.Parallel()

	opts := &terraform.Options{
		// You should update this relative path to point at your
		// hello-world-app example directory!
		TerraformDir: "../example/hello-world-app/standalone",

		Vars: map[string]interface{}{
			"mysql_config": map[string]interface{}{
				"address": "mock-value-for-test",
				"port":    3306,
			},
			"environment": fmt.Sprintf("test-%s", random.UniqueId()),
		},
	}

	// Clean up everything at the end of the test
	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)
}
