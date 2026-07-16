# Certificate Scanner

A production-ready web application to inventory and monitor TLS certificates across Azure resources: **APIM, App Gateway, App Service, Functions, Logic Apps, and Front Door**.

## Architecture

| Layer | Technology |
|---|---|
| Frontend | Bootstrap 5 + Vanilla JS (server-rendered via Flask) |
| Backend | Python 3.12 / Flask |
| Database | Azure CosmosDB (NoSQL) |
| Storage | Azure Blob Storage (CSV exports) |
| Auth | Azure AD (MSAL OAuth2) |
| Hosting | Azure App Service (Linux) |
| Monitoring | Application Insights + Log Analytics |

## Local Development

```bash
# 1. Clone and enter the repo
git clone https://github.com/luk182/certificate-scanner
cd certificate-scanner

# 2. Create virtual environment
python -m venv .venv
.venv\Scripts\activate   # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
copy .env.example .env
# Edit .env with your Azure resource values

# 5. Login to Azure (used by DefaultAzureCredential in dev)
az login

# 6. Run
flask --app app run --debug --port 5000
```

## Azure Deployment

```bash
# Deploy infrastructure (Bicep)
az deployment sub create \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/parameters/dev.bicepparam \
               tenantId="<TENANT_ID>" \
               clientId="<APP_CLIENT_ID>"
```

See `infra/parameters/dev.bicepparam` for parameters to fill in.

## Required Managed Identity Permissions

The App Service uses a **System-Assigned Managed Identity**. Grant the following roles:

### Azure RBAC (subscription or management group scope)

| Role | Purpose |
|---|---|
| `Reader` | Enumerate all resources |
| `API Management Service Reader` | Read APIM hostname configs |
| `Website Contributor` (read is sufficient) | Read App Service / Functions / Logic Apps certs |
| `Network Contributor` (or `Reader`) | Read App Gateway SSL certs |
| `Front Door Reader` | Read Front Door custom HTTPS configs |

### Key Vault (per vault)

| Model | Permission |
|---|---|
| RBAC | `Key Vault Certificate User` |
| Access Policy | `Get`, `List` on Certificates |

### Data Plane

| Resource | Role |
|---|---|
| CosmosDB | `Cosmos DB Built-in Data Contributor` |
| Storage Account | `Storage Blob Data Contributor` |
| Log Analytics DCR | `Monitoring Metrics Publisher` |

## GitHub Secrets Required

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | App Registration client ID (GitHub OIDC) |
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |
| `APP_CLIENT_ID` | App Registration client ID (MSAL login) |
| `APP_CLIENT_SECRET` | App Registration client secret |
| `FLASK_SECRET_KEY` | Random secret for Flask sessions |
| `LOG_ANALYTICS_DCE_ENDPOINT` | Data Collection Endpoint URL |
| `LOG_ANALYTICS_DCR_IMMUTABLE_ID` | Data Collection Rule immutable ID |

