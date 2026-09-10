param location string

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'sthealthapi001'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'

  resource blobServices 'blobServices' = {
    name: 'default'
    resource deploymentContainer 'containers' = {
      name: 'app-package'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

output storageName string = storage.name
output storagePrimaryBlobEndpoint string = storage.properties.primaryEndpoints.blob
output storageKey string = storage.listKeys().keys[0].value
