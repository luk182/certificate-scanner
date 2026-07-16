param location string
param env string
param appName string

var accountName = 'cosmos-${appName}-${env}'

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: accountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [{ locationName: location, failoverPriority: 0, isZoneRedundant: false }]
    consistencyPolicy: { defaultConsistencyLevel: 'Session' }
    disableLocalAuth: true
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  parent: cosmos
  name: 'certificate-scanner'
  properties: { resource: { id: 'certificate-scanner' } }
}

resource certsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
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

resource settingsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
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
