// User-Assigned Managed Identity used by GitHub Actions for OIDC deployment.
// After deploying this, set AZURE_CLIENT_ID in GitHub Secrets to the output clientId.

param location string
param env string
param appName string
param githubOrg string
param githubRepo string

var identityName = 'id-${appName}-deploy-${env}'

resource deploymentIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

// Push to main branch
resource fedCredMain 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: deploymentIdentity
  name: 'github-main'
  properties: {
    audiences: ['api://AzureADTokenExchange']
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:${githubOrg}/${githubRepo}:ref:refs/heads/main'
  }
}

// GitHub Environment: dev (must be sequential - concurrent federated credential writes are not supported)
resource fedCredEnvDev 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: deploymentIdentity
  name: 'github-env-dev'
  dependsOn: [fedCredMain]
  properties: {
    audiences: ['api://AzureADTokenExchange']
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:${githubOrg}/${githubRepo}:environment:dev'
  }
}

output principalId string = deploymentIdentity.properties.principalId
output clientId     string = deploymentIdentity.properties.clientId
output identityId   string = deploymentIdentity.id
output identityName string = deploymentIdentity.name
