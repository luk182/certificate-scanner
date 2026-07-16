param location string
param env string
param appName string

var workspaceName = 'law-${appName}-${env}'
var dceName       = 'dce-${appName}-${env}'
var dcrName       = 'dcr-${appName}-${env}'

// -- Log Analytics Workspace ----------------------------------------------
resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 90
  }
}

// Custom table for certificate alerts
resource customTable 'Microsoft.OperationalInsights/workspaces/tables@2023-09-01' = {
  parent: workspace
  name: 'CertificateAlerts_CL'
  properties: {
    schema: {
      name: 'CertificateAlerts_CL'
      columns: [
        { name: 'TimeGenerated',  type: 'datetime' }
        { name: 'CertName',       type: 'string' }
        { name: 'SNURL',          type: 'string' }
        { name: 'Resource',       type: 'string' }
        { name: 'ResourceType',   type: 'string' }
        { name: 'ExpirationDate', type: 'string' }
        { name: 'Status',         type: 'string' }
        { name: 'DaysRemaining',  type: 'int' }
      ]
    }
    retentionInDays: 90
  }
}

// -- Data Collection Endpoint ---------------------------------------------
resource dce 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = {
  name: dceName
  location: location
  properties: {
    networkAcls: { publicNetworkAccess: 'Enabled' }
  }
}

// -- Data Collection Rule ------------------------------------------------
resource dcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: dcrName
  location: location
  dependsOn: [customTable]
  properties: {
    dataCollectionEndpointId: dce.id
    streamDeclarations: {
      'Custom-CertificateAlerts_CL': {
        columns: [
          { name: 'TimeGenerated',  type: 'datetime' }
          { name: 'CertName',       type: 'string' }
          { name: 'SNURL',          type: 'string' }
          { name: 'Resource',       type: 'string' }
          { name: 'ResourceType',   type: 'string' }
          { name: 'ExpirationDate', type: 'string' }
          { name: 'Status',         type: 'string' }
          { name: 'DaysRemaining',  type: 'int' }
        ]
      }
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspace.id
          name: 'law-destination'
        }
      ]
    }
    dataFlows: [
      {
        streams: ['Custom-CertificateAlerts_CL']
        destinations: ['law-destination']
        transformKql: 'source'
        outputStream: 'Custom-CertificateAlerts_CL'
      }
    ]
  }
}

output workspaceId   string = workspace.id
output workspaceName string = workspace.name
output dceEndpoint   string = dce.properties.logsIngestion.endpoint
output dcrId         string = dcr.id
output dcrImmutableId string = dcr.properties.immutableId
