using '../main.bicep'

param location    = 'eastus'
param env         = 'dev'
param appName     = 'cert-scanner'
param tenantId    = '<YOUR_TENANT_ID>'
param clientId    = '<YOUR_APP_REGISTRATION_CLIENT_ID>'
param githubOrg   = 'luk182'
param githubRepo  = 'certificate-scanner'
