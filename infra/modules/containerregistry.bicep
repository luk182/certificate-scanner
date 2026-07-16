param location string
param env string
param appName string

// Lowercase, no hyphens, max 50 chars
var registryName = toLower(take(replace(replace('cr${appName}${env}', '-', ''), '_', ''), 50))

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  sku: { name: 'Basic' }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output loginServer string = registry.properties.loginServer
output registryName string = registry.name
output registryId   string = registry.id
