param location string
param env string
param appName string

// Key Vault names: 3-24 chars, alphanumeric + hyphens, globally unique
var vaultName = take('kv-${appName}-${env}-${uniqueString(subscription().id, appName)}', 24)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enabledForTemplateDeployment: false
    publicNetworkAccess: 'Enabled'
  }
}

// Placeholder secrets — actual values set by the CI/CD pipeline after first deploy
resource secretFlaskKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'flask-secret-key'
  properties: {
    value: 'placeholder-set-by-pipeline'
    attributes: { enabled: true }
  }
}

resource secretClientSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'azure-client-secret'
  properties: {
    value: 'placeholder-set-by-pipeline'
    attributes: { enabled: true }
  }
}

output vaultName string = keyVault.name
output vaultUri string = keyVault.properties.vaultUri
