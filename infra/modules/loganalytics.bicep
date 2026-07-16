param location string
param env string
param appName string

var workspaceName = 'law-${appName}-${env}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 90
  }
}

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

output workspaceId string = workspace.id
output workspaceName string = workspace.name
