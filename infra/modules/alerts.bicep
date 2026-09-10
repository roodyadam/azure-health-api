param appName string
param functionAppId string

resource http5xxAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${appName}-execution-alert'
  location: 'global'
  properties: {
    severity: 2
    enabled: true
    scopes: [
      functionAppId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'NoExecutions'
          metricName: 'OnDemandFunctionExecutionCount'
          operator: 'LessThanOrEqual'
          threshold: 0
          timeAggregation: 'Total'
        }
      ]
    }
    actions: []
  }
}