targetScope = 'subscription'

param location string = 'eastus'
param env string = 'dev'
param appName string = 'cert-scanner'
param tenantId string
param clientId string

var rgName = 'rg-${appName}-${env}'

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
  }
}

output appUrl string = appService.outputs.appUrl
output principalId string = appService.outputs.principalId
output resourceGroup string = rgName
