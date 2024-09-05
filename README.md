# CRM Sample Application

A sample application for building and deploying a simple CRM application.

```bash

az login -t 16b3c013-d300-468d-ac64-7eda0820b6d3

source .env

cd infra

# Use remote storage
terraform init --backend-config ./backend-secrets.tfvars

terraform apply \
-var 'base_name=crm-application-20240904' \
-var 'location=eastus2' 



\
-var 'root_dns_name=something.com' \
-var 'contact_name=John Doe' \
-var 'contact_email=someemail@something.com' #\


```