param alias string
param location string
var name = '${alias}servicebus'

resource servicebus 'Microsoft.ServiceBus/namespaces@2015-08-01' = {
  name: name
  location: location
  sku:{
    name: 'Basic'
    tier: 'Basic'
    capacity: 1
  }
  resource authrule 'AuthorizationRules' = {
    name: 'RootManageSharedAccessKey'
    properties: {
      rights: [
        'Listen'
        'Manage'
        'Send'
      ]
    }
  }

}
resource queue 'Microsoft.ServiceBus/namespaces/queues@2015-08-01' = {
    name: 'orders'
    location: location
    parent: servicebus
    properties: {
    }
  }

