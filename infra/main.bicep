targetScope = 'subscription'

param location string = 'eastus'
param cosmosLocation string = 'eastus2'          // eastus has CosmosDB capacity limits
param containerAppsLocation string = 'eastus2'   // eastus has AKS heavy usage
param env string = 'dev'
param appName string = 'cert-scanner'
param tenantId string
param clientId string
param githubOrg string = 'luk182'
param githubRepo string = 'certificate-scanner'

var rgName = 'rg-${appName}-${env}'

// Built-in role IDs (subscription scope)
var readerRoleId        = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var kvCertUserRoleId    = 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba'
var contributorRoleId   = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var userAccessAdminId   = '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'

// Deterministic names for role assignments (known at compile time)
var containerAppResourceName = 'app-${appName}-${env}'
var deployIdName             = 'id-${appName}-deploy-${env}'

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
  params: { location: cosmosLocation, env: env, appName: appName }
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

module containerRegistry 'modules/containerregistry.bicep' = {
  name: 'containerregistry'
  scope: rg
  params: { location: location, env: env, appName: appName }
}

module containerApp 'modules/containerapps.bicep' = {
  name: 'containerapps'
  scope: rg
  params: {
    location: containerAppsLocation
    env: env
    appName: appName
    cosmosEndpoint: cosmos.outputs.endpoint
    storageAccountUrl: storage.outputs.blobEndpoint
    appInsightsConnectionString: appInsights.outputs.connectionString
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    logAnalyticsWorkspaceName: logAnalytics.outputs.workspaceName
    tenantId: tenantId
    clientId: clientId
    keyVaultName: keyVault.outputs.vaultName
    registryLoginServer: containerRegistry.outputs.loginServer
  }
}

// User-Assigned Managed Identity for GitHub Actions OIDC
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

// Resource-level role assignments for Container App MI
module roleAssignments 'modules/roleassignments.bicep' = {
  name: 'roleassignments'
  scope: rg
  params: {
    containerAppPrincipalId:   containerApp.outputs.principalId
    cosmosAccountName:         cosmos.outputs.cosmosAccountName
    storageAccountName:        storage.outputs.storageAccountName
    keyVaultName:              keyVault.outputs.vaultName
    logAnalyticsWorkspaceName: logAnalytics.outputs.workspaceName
    dcrResourceId:             logAnalytics.outputs.dcrId
    containerRegistryName:     containerRegistry.outputs.registryName
  }
}

// Subscription-scope: Container App MI - Reader + KV Certificate User
resource appSvcReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, containerAppResourceName, readerRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalId: containerApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appSvcKvCertUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, containerAppResourceName, kvCertUserRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvCertUserRoleId)
    principalId: containerApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// Subscription-scope: Deployment Identity - Contributor + User Access Administrator
resource deployContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, deployIdName, contributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: deploymentIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deployUAA 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, deployIdName, userAccessAdminId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', userAccessAdminId)
    principalId: deploymentIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output appUrl                        string = containerApp.outputs.appUrl
output containerAppPrincipalId       string = containerApp.outputs.principalId
output containerAppName              string = containerApp.outputs.containerAppName
output acrLoginServer                string = containerRegistry.outputs.loginServer
output acrName                       string = containerRegistry.outputs.registryName
output deploymentIdentityClientId    string = deploymentIdentity.outputs.clientId
output deploymentIdentityPrincipalId string = deploymentIdentity.outputs.principalId
output keyVaultName                  string = keyVault.outputs.vaultName
output resourceGroup                 string = rgName
output dceEndpoint                   string = logAnalytics.outputs.dceEndpoint
output dcrImmutableId                string = logAnalytics.outputs.dcrImmutableId
