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