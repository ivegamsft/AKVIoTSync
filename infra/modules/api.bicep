param location string = resourceGroup().location
param name string
param tags object

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var functionAppName = '${resourceToken}-func'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${resourceToken}-ai'
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

output API_IDENTITY_PRINCIPAL_ID string = functionApp.identity.principalId
output API_ID string = functionApp.id
output API_NAME string = functionApp.name
output API_URI string = 'https://${functionApp.properties.defaultHostName}'
output FUNCTION_ID string = function.id
