param location string
param env string
param appName string

// Storage account names must be 3-24 chars, lowercase alphanumeric only
var storageName = toLower(take(replace(replace('st${appName}${env}', '-', ''), '_', ''), 24))

resource storage 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: storage
  name: 'default'
}

resource exportsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: blobService
  name: 'exports'
  properties: { publicAccess: 'None' }
}

output blobEndpoint string = storage.properties.primaryEndpoints.blob
output storageAccountName string = storage.name
