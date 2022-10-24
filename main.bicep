// playground:https://bicepdemo.z22.web.core.windows.net/
param location string = resourceGroup().location
param yourName string
param ramdom string

// Azure Functions
var functionAppName = 'fn-${toLower(yourName)}-${ramdom}'
var appServicePlanName = 'FunctionPlan-${toLower(yourName)}-${ramdom}'
var appInsightsName = 'AppInsights-${toLower(yourName)}-${ramdom}'
var storageAccountName = substring('fnstor${toLower(yourName)}${toLower(replace(ramdom, '-', ''))}', 0, 24)
var containerName = 'files'

// Azure Cosmos DB
var accountName = 'cosmos-${toLower(yourName)}-${ramdom}'
var databaseName = 'CommentDB'
var cosmosContainerName = 'Comments'

// Azure SignalR Service
var signalrName = 'sigr-${toLower(yourName)}-${ramdom}'
var pricingTier = 'Free_F1'
var capacity = 1
var serviceMode = 'Serverless'
var enableConnectivityLogs = true
var enableMessagingLogs = true
var enableLiveTrace = true


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storageAccount.name}/default/${containerName}'
  properties: {
    publicAccess:'Container'
  }
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = {
  name: toLower(accountName)
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    //enableFreeTier: true
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-10-15' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-10-15' = {
  parent: cosmosDB
  name: cosmosContainerName
  properties: {
    resource: {
      id: cosmosContainerName
      partitionKey: {
        paths: [
          '/partitionKey'
        ]
        kind: 'Hash'
      }
     }
     options:{}
    }
  }

  resource signalR 'Microsoft.SignalRService/signalR@2022-02-01' = {
    name: signalrName
    location: location
    sku: {
      capacity: capacity
      name: pricingTier
    }
    kind: 'SignalR'
    properties: {
      tls: {
        clientCertEnabled: false
      }
      features: [
        {
          flag: 'ServiceMode'
          value: serviceMode
        }
        {
          flag: 'EnableConnectivityLogs'
          value: string(enableConnectivityLogs)
        }
        {
          flag: 'EnableMessagingLogs'
          value: string(enableMessagingLogs)
        }
        {
          flag: 'EnableLiveTrace'
          value: string(enableLiveTrace)
        }
      ]
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
    }
  }

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource plan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    name: 'Y1'
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsights.properties.InstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'COSMOSDB_ACCOUNT'
          value: cosmosAccount.properties.documentEndpoint
        }
        {
          name: 'COSMOSDB_KEY'
          value: cosmosAccount.listKeys().primaryMasterKey
        }
        {
          name: 'COSMOSDB_DATABASENAME'
          value: databaseName
        }
        {
          name: 'COSMOSDB_CONTAINERNAME'
          value: cosmosContainerName
        }
        {
          name: 'COSMOSDB_CONNECTION_STRING'
          value: 'AccountEndpoint=${cosmosAccount.properties.documentEndpoint};AccountKey=${cosmosAccount.listKeys().primaryMasterKey};'
        }
        {
          name: 'SIGNALR_CONNECTION_STRING'
          value: 'Endpoint=https://${signalrName}.service.signalr.net;AccessKey=${listKeys(signalR.id, signalR.apiVersion).primaryKey};Version=1.0;'
        }
      ]
    }
    httpsOnly: true
  }
}

output functionAppName string = functionAppName
