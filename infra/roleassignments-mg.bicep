// ============================================================
// Management-Group scope role assignments
// Deploy with:
//   az deployment mg create \
//     --management-group-id <ROOT_MG_ID> \
//     --location eastus \
//     --template-file infra/roleassignments-mg.bicep \
//     --parameters appServicePrincipalId=<PRINCIPAL_ID>
//
// Run AFTER main.bicep outputs appServicePrincipalId.
// Grants the App Service Managed Identity broad read access
// across ALL subscriptions in the management group so the
// certificate scanner can discover resources everywhere.
// ============================================================

targetScope = 'managementGroup'

@description('Principal ID of the App Service System-Assigned Managed Identity (output of main.bicep)')
param appServicePrincipalId string

// -- Built-in role IDs --------------------------------------------------------
var readerRoleId        = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'  // Reader
var kvCertUserRoleId    = 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba'  // Key Vault Certificate User
var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'  // Key Vault Secrets User
var websiteContribId    = 'de139f84-1756-47ae-9be6-808fbbe84772'  // Website Contributor (read App Svc certs)

// -- Reader – enumerate all resources in all subscriptions -------------------
resource readerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, appServicePrincipalId, readerRoleId)
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// -- Key Vault Certificate User – read certs from customer Key Vaults ---------
resource kvCertUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, appServicePrincipalId, kvCertUserRoleId)
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', kvCertUserRoleId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// -- Key Vault Secrets User – read secrets referenced by resources -------------
resource kvSecretsUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, appServicePrincipalId, kvSecretsUserRoleId)
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsUserRoleId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// -- Website Contributor – read App Service / Functions certificate bindings ---
resource websiteContribAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, appServicePrincipalId, websiteContribId)
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', websiteContribId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
