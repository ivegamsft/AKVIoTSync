targetScope = 'subscription'

@minLength(1)
@description('Primary location for all resources')
param location string

@minLength(1)
@maxLength(50)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string

@description('Id of the user or app to assign application roles')
param principalId string = ''

var tags = { 'azd-env-name': name }

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'akv-iot-sync-${name}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  name: 'resources'
  scope: rg
  params: {
    location: location
    name: name
    principalId: principalId
    tags: tags
  }
}

output AZURE_LOCATION string = location
output API_IDENTITY_PRINCIPAL_ID string = resources.outputs.API_IDENTITY_PRINCIPAL_ID
output API_NAME string = resources.outputs.API_NAME
output API_URI string = resources.outputs.API_URI
