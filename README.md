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

```bash
az group show --name rg-health-api-dev
```

If it doesn't exist yet, create it:

```bash
az group create --name rg-health-api-dev --location eastus
```

### 2. One-off setup: give the pipeline permission to deploy

This only needs doing once per resource group. It's the classic chicken and egg problem: GitHub Actions authenticates fine via OIDC, but without the right role assignment on the resource group, it still can't actually deploy anything.

There are two ways round having to repeat this. One is to keep the resource group itself out of the teardown process entirely, so it's never deleted along with the rest of the infrastructure, since role assignments live at the resource group level and survive as long as it does. The other is adding a bootstrap step to the pipeline that creates the resource group before deploying main.bicep. Either way, something still needs permission to carry out that first step, so it can't fully remove the manual part, only move it.

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

## Assumptions

- I deployed to `eastus` rather than `uksouth`, because the free trial subscription had a Y1 quota of zero in every UK/EU region I tried.
- I used FC1 instead of the classic Y1 Consumption plan, for the same reason.
- I didn't set up VNet integration or private networking, since the brief didn't ask for it and a public endpoint is fine for a health-check demo.
- I kept everything to one flat `dev` environment, with no separate staging or production setup.
- The deployment package uses Managed Identity for storage access, since FC1 requires it. I left the runtime storage connection on a key, though.
- I used Node 20 for the Function App runtime. Node 24 is the current recommended LTS, so I'd update this if I were taking it further.
- I went with `Standard_LRS` for the storage account, the cheapest replication tier, which is fine for a dev workload but not something I'd choose for anything holding real data.
- I noticed the storage account defaults to a minimum TLS version of 1.0. I'd raise this to 1.2 for anything beyond a demo.
- I scoped the pipeline's identity to Contributor and User Access Administrator on the resource group only, not the subscription, to keep the blast radius small.
- I set the `/api/health` endpoint to anonymous auth rather than a function key, since it's a public health check with nothing sensitive in it.
- I made the repository public, following the brief's stated preference.