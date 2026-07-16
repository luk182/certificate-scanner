param location string
param env string
param appName string
param cosmosEndpoint string
param storageAccountUrl string
param appInsightsConnectionString string
param logAnalyticsWorkspaceId string
param tenantId string
param clientId string

var planName = 'asp-${appName}-${env}'
var siteName = 'app-${appName}-${env}'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: planName
  location: location
  sku: { name: 'B2', tier: 'Basic' }
  properties: { reserved: true }
  kind: 'linux'
}

resource appServiceApp 'Microsoft.Web/sites@2023-01-01' = {
  name: siteName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.12'
      appCommandFile: 'startup.sh'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        { name: 'AZURE_TENANT_ID',               value: tenantId }
        { name: 'AZURE_CLIENT_ID',               value: clientId }
        { name: 'COSMOS_ENDPOINT',               value: cosmosEndpoint }
        { name: 'COSMOS_DATABASE',               value: 'certificate-scanner' }
        { name: 'STORAGE_ACCOUNT_URL',           value: storageAccountUrl }
        { name: 'APPINSIGHTS_CONNECTION_STRING', value: appInsightsConnectionString }
        { name: 'LOG_ANALYTICS_WORKSPACE_ID',    value: logAnalyticsWorkspaceId }
        { name: 'FLASK_ENV',                     value: env }
        { name: 'SCM_DO_BUILD_DURING_DEPLOYMENT', value: 'true' }
      ]
    }
  }
}

output principalId string = appServiceApp.identity.principalId
output appUrl string = 'https://${appServiceApp.properties.defaultHostName}'
