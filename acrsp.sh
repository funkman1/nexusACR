#!/bin/bash
ACR_NAME=<INSERT_YOUR_ACR_NAME>
SERVICE_PRINCIPAL_NAME=<INSERT_YOUR_SERVICE_PRINCIPAL_NAME>

ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query "id" --output tsv)

PASSWORD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role acrpull --query "password" --output tsv)
USER_NAME=$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query "[].appId" --output tsv)

echo "Service principal ID: $USER_NAME"
echo "Service principal password: $PASSWORD"