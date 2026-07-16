param location string
param env string
param appName string
param cosmosEndpoint string
param storageAccountUrl string
param appInsightsConnectionString string
param logAnalyticsWorkspaceId string
param tenantId string
param clientId string
param keyVaultName string
param registryLoginServer string
param logAnalyticsWorkspaceName string

var envName          = 'cae-${appName}-${env}'
var containerAppName = 'app-${appName}-${env}'

// Reference existing Log Analytics workspace for Container Apps environment logs
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: envName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logWorkspace.properties.customerId
        sharedKey: logWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: registryLoginServer
          identity: 'system'
        }
      ]
      // Placeholder secrets – the pipeline will overwrite with values from Key Vault
      secrets: [
        { name: 'flask-secret-key',    value: 'placeholder-update-via-pipeline' }
        { name: 'azure-client-secret', value: 'placeholder-update-via-pipeline' }
      ]
    }
    template: {
      containers: [
        {
          name: 'cert-scanner'
          // Public placeholder; pipeline updates this to the ACR image
          image: 'mcr.microsoft.com/k8se/quickstart:latest'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            { name: 'AZURE_TENANT_ID',               value: tenantId }
            { name: 'AZURE_CLIENT_ID',               value: clientId }
            { name: 'COSMOS_ENDPOINT',               value: cosmosEndpoint }
            { name: 'COSMOS_DATABASE',               value: 'certificate-scanner' }
            { name: 'STORAGE_ACCOUNT_URL',           value: storageAccountUrl }
            { name: 'APPINSIGHTS_CONNECTION_STRING', value: appInsightsConnectionString }
            { name: 'LOG_ANALYTICS_WORKSPACE_ID',    value: logAnalyticsWorkspaceId }
            { name: 'FLASK_ENV',                     value: env }
            { name: 'KEY_VAULT_NAME',                value: keyVaultName }
            // Secrets are injected from Container Apps secrets configuration above
            { name: 'SECRET_KEY',          secretRef: 'flask-secret-key' }
            { name: 'AZURE_CLIENT_SECRET', secretRef: 'azure-client-secret' }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 2
        rules: [
          {
            name: 'http-scaler'
            http: { metadata: { concurrentRequests: '10' } }
          }
        ]
      }
    }
  }
}

output appUrl           string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output principalId      string = containerApp.identity.principalId
output containerAppName string = containerApp.name
