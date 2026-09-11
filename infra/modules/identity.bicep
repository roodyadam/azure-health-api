param location string
param appName string
param storageId string
param deploymentTimestamp string = utcNow()

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${appName}-identity'
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageId, identity.id, 'StorageBlobDataOwner', deploymentTimestamp)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output identityId string = identity.id
output identityPrincipalId string = identity.properties.principalId