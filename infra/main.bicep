targetScope = 'subscription'

param location string = 'eastus'
param env string = 'dev'
param appName string = 'cert-scanner'
param tenantId string
param clientId string
param githubOrg string = 'luk182'
param githubRepo string = 'certificate-scanner'

var rgName = 'rg-${appName}-${env}'

// ── Built-in role IDs (subscription scope) ───────────────────────────────────
var readerRoleId        = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var kvCertUserRoleId    = 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba'
var contributorRoleId   = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var userAccessAdminId   = '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
}

module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'loganalytics'
  scope: rg
  params: { location: location, env: env, appName: appName }
}

module appInsights 'modules/appinsights.bicep' = {
  name: 'appinsights'
  scope: rg
  params: {
    location: location
    env: env
    appName: appName
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

module cosmos 'modules/cosmosdb.bicep' = {
  name: 'cosmosdb'
  scope: rg
  params: { location: location, env: env, appName: appName }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: { location: location, env: env, appName: appName }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: { location: location, env: env, appName: appName }
}

module appService 'modules/appservice.bicep' = {
  name: 'appservice'
  scope: rg
  params: {
    location: location
    env: env
    appName: appName
    cosmosEndpoint: cosmos.outputs.endpoint
    storageAccountUrl: storage.outputs.blobEndpoint
    appInsightsConnectionString: appInsights.outputs.connectionString
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tenantId: tenantId
    clientId: clientId
    keyVaultName: keyVault.outputs.vaultName
  }
} ───────────────────
module deploymentIdentity 'modules/deploymentidentity.bicep' = {
  name: 'deploymentidentity'
  scope: rg
  params: {
    location: location
    env: env
    appName: appName
    githubOrg: githubOrg
    githubRepo: githubRepo
  }
}

// ── Resource-level role assignments for App Service MI ───────────────────────
module roleAssignments 'modules/roleassignments.bicep' = {
  name: 'roleassignments'
  scope: rg
  params: {
    appServicePrincipalId:    appService.outputs.principalId
    cosmosAccountName:        cosmos.outputs.cosmosAccountName
    storageAccountName:       storage.outputs.storageAccountName
    keyVaultName:             keyVault.outputs.vaultName
    logAnalyticsWorkspaceName: logAnalytics.outputs.workspaceName
    dcrResourceId:            logAnalytics.outputs.dcrId
  }
}

// ── Subscription-scope: App Service MI gets Reader + KV Certificate User ─────
resource appSvcReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, appService.outputs.principalId, readerRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalId: appService.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appSvcKvCertUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, appService.outputs.principalId, kvCertUserRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvCertUserRoleId)
    principalId: appService.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// ── Subscription-scope: Deployment Identity gets Contributor + UAA ────────────
resource deployContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, deploymentIdentity.outputs.principalId, contributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: deploymentIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deployUAA 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, deploymentIdentity.outputs.principalId, userAccessAdminId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', userAccessAdminId)
    principalId: deploymentIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────
output appUrl                        string = appService.outputs.appUrl
output appServicePrincipalId         string = appService.outputs.principalId
output deploymentIdentityClientId    string = deploymentIdentity.outputs.clientId
output deploymentIdentityPrincipalId string = deploymentIdentity.outputs.principalId
output keyVaultName                  string = keyVault.outputs.vaultName
output resourceGroup                 string = rgName
output appServiceName                string = 'app-${appName}-${env}'
output dceEndpoint                   string = logAnalytics.outputs.dceEndpoint
output dcrImmutableId                string = logAnalytics.outputs.dcrImmutableId
