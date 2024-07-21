# azure-databricks-playground

This project serves as a playground for setting up Databricks workspaces within the Azure Cloud.

## Minimum Setup Requirements

* An [Azure Cloud](https://azure.microsoft.com/en-us/) account
* [azure-cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed
  * Login with `az login`
* A [Terraform Cloud](https://app.terraform.io/app/organizations) API token for the configured organization/workspace
  * This can be set in `~/.terraformrc`, i.e.:
    ```
    credentials "app.terraform.io" {
      token = "<YOUR_API_TOKEN>"
    }
    ```
  * Alternatively, the `cloud {...}` block in `providers.tf` can be removed to store terraform state locally
* Run `terraform apply -var-file="terraform.tfvars"`