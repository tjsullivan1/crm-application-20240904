# CRM Sample Application

A sample application for building and deploying a simple CRM application.

## Getting Started and Setup

```bash

source .env

az login -t $ARM_TENANT_ID

```

## Layer 0: Global Library

> NOTE: Nothing to do on this step, it is a library that is used by other layers.

## Layer 1: Global Infrastructure

This layer is used to create resources like hub VNETs, DNS Zones, observability tools and other global resources.

```bash

cd infra/layer1-global_infrastructure/

# Uses local storage for state
terraform init

# Apply the Terraform
terraform apply \
-var "base_name=crm-v1-l1-globalcore" \
-var "location=$LOCATION"

```

## Layer 2: Product Platform

This layer is used to create shared application or platform resources like spoke VNETs, storage accounts, key vaults, databases and other resources.

```bash

cd infra/layer2-product_platform/

# Uses local storage for state
terraform init

# Apply the Terraform
terraform apply \
-var "base_name=crm-v1-l2-appcore" \
-var "location=$LOCATION"

```

## Layer 3: Application

This layer is used to create specific application resources like VMs, app plans and services, storage accounts, etc.

### Sample Application 001

```bash

cd infra/layer3-application/app001/

# Uses local storage for state
terraform init

KV_URI=$(az keyvault show -g crm-v1-l2-appcore --name crm-v1-l2-appcore-kv --query properties.vaultUri -o tsv)
SUBNET_ID=$(az network vnet subnet show -g crm-v1-l1-globalcore --vnet-name crm-v1-l1-globalcore-vnet --name app-outbound --query id -o tsv)
USER_ID=$(az identity show -g crm-v1-l2-appcore --name crm-v1-l2-appcore-id --query id -o tsv)  # NOTE: This is case-sensitive and "resourcegroups" => "resourceGroups"

# USER_ID='/subscriptions/30c417b6-b3c1-4b62-94c9-0d3a80a182e9/resourceGroups/crm-v1-l2-appcore/providers/Microsoft.ManagedIdentity/userAssignedIdentities/crm-v1-l2-appcore-id'

# Apply the Terraform
terraform apply \
-var "base_name=crm-v1-l3-app001" \
-var "location=$LOCATION" \
-var "outbound_subnet_id=$SUBNET_ID" \
-var "user_managed_identity=$USER_ID" \
-var "key_vault_uri=$KV_URI"

```