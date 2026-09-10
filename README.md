## Architecture Diagram

![Architecture diagram](./Azure_Exercise.drawio.svg)


Design

The task asked for a simple health-check API on Azure, using an Azure Function App, a Storage Account and Application Insights, deployed with Bicep and no manual steps in the portal, delivered through a pipeline.

The app itself is a single Node.js function that returns a health status. Nothing complicated there.

For the infrastructure, I split the deployment into reusable Bicep modules — storage, Application Insights, hosting plan, managed identity, Key Vault, alerts, and the Function App itself — composed from a single `main.bicep`. I originally planned to use the standard Consumption plan (Y1), but hit a quota limit of zero on the free trial subscription, so I switched to the newer Flex Consumption plan (FC1) instead. This plan needs the Function App to use a Managed Identity to read its own deployment files from storage, rather than a stored key, which happened to satisfy the optional Managed Identity requirement as a side effect.

I also added a Key Vault as one of the optional stretch goals. It stores the storage account key as a secret, with RBAC-only access (no legacy access policies) granted solely to the Function App's managed identity. The app doesn't actually read this secret at runtime — its storage connection is already fully identity-based and needs no key at all, which is the stronger pattern. The vault instead sits alongside it as a defense-in-depth measure: the key exists somewhere secured behind the same identity boundary rather than nowhere at all, in case anything ever legitimately needs it. Wiring the app to actually resolve the key through a Key Vault reference is possible and is listed below under improvements, but I didn't do it by default since it would mean introducing a stored credential the app doesn't currently need.

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
- The deployment package and the runtime storage connection both use Managed Identity rather than a key, since FC1 requires identity-based access for deployment and I extended the same approach to the runtime connection rather than mixing patterns.
- I scoped the pipeline's identity to Contributor and User Access Administrator on the resource group only, not the subscription, to keep the blast radius small.
- I set the `/api/health` endpoint to anonymous auth rather than a function key, since it's a public health check with nothing sensitive in it.
- I made the repository public, following the brief's stated preference.

## What I'd Improve With More Time

- Wire the Function App's storage connection to actually resolve the key via a Key Vault reference (`@Microsoft.KeyVault(SecretUri=...)`), so the Key Vault integration is exercised end-to-end rather than just holding a secret in reserve. Worth doing to demonstrate the full pattern, even though the current identity-based connection is arguably the more secure default.
- Separate staging and production environments, parameterized through Bicep and pipeline stages, instead of the one flat `dev` environment I have now.
- Add VNet integration and private networking instead of a public endpoint. Reasonable to skip for a demo health check, not for anything handling real traffic.
- Raise the storage account's minimum TLS version from its default of 1.0 to 1.2.
- Move off `Standard_LRS` to a redundancy tier appropriate for real data — it's fine for a dev workload but not something I'd choose otherwise.
- Upgrade the Function App runtime from Node 20 to Node 24, the current LTS.
- Give the metric alert an action group — right now it fires but notifies no one — and add a couple more alerts, such as HTTP error rate.
- Add automated tests: unit tests for the function itself, and a post-deploy smoke test in the pipeline that hits `/api/health` and checks the response.
