param location string
param env string
param appName string

var accountName = 'cosmos-${appName}-${env}'

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2024-02-15-preview' = {
  name: accountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [{ locationName: location, failoverPriority: 0 }]
    consistencyPolicy: { defaultConsistencyLevel: 'Session' }
    disableLocalAuth: true
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-02-15-preview' = {
  parent: cosmos
  name: 'certificate-scanner'
  properties: { resource: { id: 'certificate-scanner' } }
}

resource certsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-02-15-preview' = {
  parent: database
  name: 'certificates'
  properties: {
    resource: {
      id: 'certificates'
      partitionKey: { paths: ['/resource_type'], kind: 'Hash' }
      indexingPolicy: { indexingMode: 'consistent', includedPaths: [{ path: '/*' }] }
    }
  }
}

resource settingsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-02-15-preview' = {
  parent: database
  name: 'settings'
  properties: {
    resource: {
      id: 'settings'
      partitionKey: { paths: ['/id'], kind: 'Hash' }
    }
  }
}

output endpoint string = cosmos.properties.documentEndpoint
output cosmosAccountName string = cosmos.name
