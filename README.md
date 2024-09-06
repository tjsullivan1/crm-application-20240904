# CRM Sample Application

A sample application for building and deploying a simple CRM application.

```bash

source .env

az login -t $ARM_TENANT_ID

cd infra

# Uses local storage for state
terraform init

# Apply the Terraform
terraform apply \
-var 'base_name=crm-application-20240904' \
-var 'location=eastus2' 

```