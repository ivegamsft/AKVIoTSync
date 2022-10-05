# Azure Key Vault Certificate sync to IoT Hub

Sample showing how to use an Azure Function to sync x509 certificates from Azure Key Vault to IoT Hub.

## Setup

This sample is configured as an [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) compatible solution.

To deploy this sample:

1. Ensure your local machine has the Azure Developer CLI and prerequisites installed.
1. Clone the repo locally and change directories into the repo root
1. Login to your Azure environment with Azure CLI: `az login`
1. Run `azd up` and follow the on-screen prompts. For the Environment name, use something short (i.e. `dev`, `foo`, etc)

## Usage

To test this sample:

1. Navigate to the Azure Key Vault deployed within the `akv-iot-sync-<env>` resource group that was created when running `azd up`
1. Go to the Key Vault Certificates section of and generate a new self-signed certificate
1. After a few minutes, navigate to the IoT Hub Certificates section and verify the certificate has been added

## License

[MIT License.](license) Copyright (c) 2022 Ryan Graham