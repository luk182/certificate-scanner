// Resource-group scoped role assignments for the Container App Managed Identity
// Subscription-level assignments (Reader, KV Cert User) live in main.bicep

param containerAppPrincipalId   string
param cosmosAccountName         string
param storageAccountName        string
param keyVaultName              string
param logAnalyticsWorkspaceName string
param dcrResourceId             string   // Full resource ID of the Data Collection Rule
param containerRegistryName     string

// -- Cosmos DB Built-in Data Contributor -------------------------------------
// Role definition ID: 00000000-0000-0000-0000-000000000002 (Cosmos-specific RBAC)
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' existing = {
  name: cosmosAccountName
}

resource cosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  parent: cosmosAccount
  name: guid(cosmosAccount.id, containerAppPrincipalId, '00000000-0000-0000-0000-000000000002')
  properties: {
    roleDefinitionId: '${cosmosAccount.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    principalId: containerAppPrincipalId
    scope: cosmosAccount.id
  }
}

// -- Storage Blob Data Contributor --------------------------------------------
var storageBlobDataContributorId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageAccountName
}

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, containerAppPrincipalId, storageBlobDataContributorId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorId)
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// -- Key Vault Secrets User (read flask-secret-key + azure-client-secret) -----
var kvSecretsUserId = '4633458b-17de-408a-b874-0445c86b69e6'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource kvSecretsUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, containerAppPrincipalId, kvSecretsUserId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsUserId)
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// -- Monitoring Metrics Publisher (send custom logs to DCR) -------------------
var monitoringMetricsPublisherId = '3913510d-42f4-4e42-8a64-420c390055eb'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource monitoringWorkspaceAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsWorkspace.id, containerAppPrincipalId, monitoringMetricsPublisherId)
  scope: logAnalyticsWorkspace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherId)
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Monitoring Metrics Publisher on the DCR itself
resource dcrResource 'Microsoft.Insights/dataCollectionRules@2022-06-01' existing = {
  name: last(split(dcrResourceId, '/'))
}

resource monitoringDcrAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(dcrResource.id, containerAppPrincipalId, monitoringMetricsPublisherId)
  scope: dcrResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherId)
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// -- AcrPull (Container App MI pulls images from ACR) -----------------------
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, containerAppPrincipalId, acrPullRoleId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}
