param location string = resourceGroup().location
param name string
param tags object

var resourceToken = 'a${toLower(uniqueString(subscription().id, name, location))}'
var functionAppName = '${resourceToken}-func'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${resourceToken}-ai'
}

resource iotHub 'Microsoft.Devices/IotHubs@2022-04-30-preview' existing = {
  name: '${resourceToken}-iothub'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: '${resourceToken}stg'
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource plan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: '${resourceToken}-asp'
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  tags: union(tags, {
    'azd-service-name': 'api'
  })
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.9'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${applicationInsights.properties.InstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'SUBSCRIPTION_ID'
          value: subscription().subscriptionId
        }
        {
          name: 'RESOURCE_GROUP_NAME'
          value: resourceGroup().name
        }
        {
          name: 'IOTHUB_NAME'
          value: iotHub.name
        }
      ]
    }
    httpsOnly: true
  }
}

resource function 'Microsoft.Web/sites/functions@2022-03-01' = {
  name: 'KeyVaultCertificateVersionCreated'
  parent: functionApp
  properties: {
    config: any({
      disabled: false
      bindings: [
        {
          type: 'eventGridTrigger'
          name: 'event'
          direction: 'in'
        }
      ]
    })
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: '${resourceToken}-kvlt'
}

resource keyVaultCertificatesOfficerRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'a4417e6f-fecd-4de8-b567-7b0420556985'
}

resource functionAppKeyVaultCertificatesOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionApp.id, keyVaultCertificatesOfficerRole.id, keyVault.id)
  scope: keyVault
  properties: {
    principalId: functionApp.identity.principalId
    roleDefinitionId: keyVaultCertificatesOfficerRole.id
  }
}

resource contributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource functionAppIoTHubContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionApp.id, contributorRole.id, iotHub.id)
  scope: iotHub
  properties: {
    roleDefinitionId: contributorRole.id
    principalId: functionApp.identity.principalId
  }
}

resource iotHubDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '4fc6c259-987e-4a07-842e-c321cc9d413f'
}

resource functionAppIoTHubDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionApp.id, iotHubDataContributorRole.id, iotHub.id)
  scope: iotHub
  properties: {
    roleDefinitionId: iotHubDataContributorRole.id
    principalId: functionApp.identity.principalId
  }
}

output API_IDENTITY_PRINCIPAL_ID string = functionApp.identity.principalId
output API_ID string = functionApp.id
output API_NAME string = functionApp.name
output API_URI string = 'https://${functionApp.properties.defaultHostName}'
output FUNCTION_ID string = function.id
