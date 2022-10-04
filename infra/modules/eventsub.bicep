param location string = resourceGroup().location
param name string

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var functionAppName = '${resourceToken}-func'

resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' existing = {
  name: '${resourceToken}-kvlt-topic'
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: functionAppName
}

resource eventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-12-01' = {
  name: '${resourceToken}-kvlt-topic-sub'
  parent: systemTopic
  properties: {
    destination: {
      properties: {
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
        resourceId: '${functionApp.id}/functions/KeyVaultCertificateVersionCreated'
      }
      endpointType: 'AzureFunction'
    }
    filter: {
      includedEventTypes: [
        'Microsoft.KeyVault.CertificateNewVersionCreated'
      ]
    }
  }
}
