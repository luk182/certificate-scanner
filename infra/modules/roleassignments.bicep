// Resource-group scoped role assignments for the App Service Managed Identity
// Subscription-level assignments (Reader, KV Cert User) live in main.bicep

param appServicePrincipalId string
param cosmosAccountName       string
param storageAccountName      string
param keyVaultName            string
param logAnalyticsWorkspaceName string
param dcrResourceId           string   // Full resource ID of the Data Collection Rule

// -- Cosmos DB Built-in Data Contributor -------------------------------------
// Role definition ID: 00000000-0000-0000-0000-000000000002 (Cosmos-specific RBAC)
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' existing = {
  name: cosmosAccountName
}

resource cosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  parent: cosmosAccount
  name: guid(cosmosAccount.id, appServicePrincipalId, '00000000-0000-0000-0000-000000000002')
  properties: {
    roleDefinitionId: '${cosmosAccount.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    principalId: appServicePrincipalId
    scope: cosmosAccount.id
  }
}

// -- Storage Blob Data Contributor --------------------------------------------
var storageBlobDataContributorId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageAccountName
}

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, appServicePrincipalId, storageBlobDataContributorId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// -- Key Vault Secrets User (read flask-secret-key + azure-client-secret) -----
var kvSecretsUserId = '4633458b-17de-408a-b874-0445c86b69e6'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource kvSecretsUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appServicePrincipalId, kvSecretsUserId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsUserId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// -- Monitoring Metrics Publisher (send custom logs to DCR) -------------------
var monitoringMetricsPublisherId = '3913510d-42f4-4e42-8a64-420c390055eb'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource monitoringWorkspaceAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsWorkspace.id, appServicePrincipalId, monitoringMetricsPublisherId)
  scope: logAnalyticsWorkspace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Monitoring Metrics Publisher on the DCR itself
resource dcrResource 'Microsoft.Insights/dataCollectionRules@2022-06-01' existing = {
  name: last(split(dcrResourceId, '/'))
}

resource monitoringDcrAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(dcrResource.id, appServicePrincipalId, monitoringMetricsPublisherId)
  scope: dcrResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
