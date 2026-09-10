param location string = resourceGroup().location
param appName string = 'health-api-${uniqueString(resourceGroup().id)}'

module storageModule 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
  }
}

module insightsModule 'modules/insights.bicep' = {
  name: 'insightsDeployment'
  params: {
    location: location
    appName: appName
  }
}

module hostingPlanModule 'modules/hostingPlan.bicep' = {
  name: 'hostingPlanDeployment'
  params: {
    location: location
    appName: appName
  }
}

module identityModule 'modules/identity.bicep' = {
  name: 'identityDeployment'
  params: {
    location: location
    appName: appName
    storageName: storageModule.outputs.storageName
  }
}

module alertsModule 'modules/alerts.bicep' = {
  name: 'alertsDeployment'
  params: {
    appName: appName
    functionAppId: functionAppModule.outputs.functionAppId
  }
}

module keyVaultModule 'modules/keyVault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    identityPrincipalId: identityModule.outputs.identityPrincipalId
    storageKey: storageModule.outputs.storageKey
  }
}

module functionAppModule 'modules/functionApp.bicep' = {
  name: 'functionAppDeployment'
  params: {
    location: location
    hostingPlanId: hostingPlanModule.outputs.hostingPlanId
    identityId: identityModule.outputs.identityId
    storageName: storageModule.outputs.storageName
    storagePrimaryBlobEndpoint: storageModule.outputs.storagePrimaryBlobEndpoint
    instrumentationKey: insightsModule.outputs.instrumentationKey
  }
}

output functionAppUrl string = functionAppModule.outputs.functionAppUrl
