## Architecture Diagram

![Architecture diagram](./Azure_Exercise.drawio.svg)


Design

The task asked for a simple health-check API on Azure, using an Azure Function App, a Storage Account and Application Insights, deployed with Bicep and no manual steps in the portal, delivered through a pipeline.

The app itself is a single Node.js function that returns a health status. Nothing complicated there.

For the infrastructure, I used one Bicep file that deploys everything. I originally planned to use the standard Consumption plan (Y1), but hit a quota limit of zero on the free trial subscription, so I switched to the newer Flex Consumption plan (FC1) instead. This plan needs the Function App to use a Managed Identity to read its own deployment files from storage, rather than a stored key, which happened to satisfy the optional Managed Identity requirement as a side effect.

For CI/CD I used GitHub Actions rather than Azure DevOps Pipelines. This matches my existing experience running similar pipelines against AWS, using the same secure login method (OIDC) with no stored passwords or secrets. I've also included a reference Azure DevOps pipeline (azure-pipelines.yml) for comparison, though it isn't connected to a live project. 

## How to deploy          

### Prerequisites         

- Azure CLI installed     
- Node.js 20+

### 1. Check if the resource group exists
​```bash
az group show --name rg-health-api-dev
​```
If it doesn't exist yet, create it:
​```bash
az group create --name rg-health-api-dev --location eastus
​```


### 2. One-off setup: give the pipeline permission to deploy
This only needs doing once per resource group. See "The bootstrapping problem" below for why, and for the exact commands.

### 3. Deploy
Push to `main`. The pipeline will:
1. Install dependencies
2. Log in to Azure via OIDC
3. Deploy the infrastructure (Bicep)
4. Deploy the function code

### Deploying manually, without the pipeline
```bash
az deployment group create --resource-group rg-health-api-dev --template-file infra/main.bicep
func azure functionapp publish <function-app-name>
```

### Running it locally
```bash
npm install
func start
curl http://localhost:7071/api/health
```