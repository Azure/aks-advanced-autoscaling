
param location string = resourceGroup().location
param aksVersion string = '1.19.13'

param alias string
@allowed([
  'australiaeast'
  'eastus'
  'eastus2'
  'northeurope'
  'southcentralus'
])
param loadTestingLocation string = 'southcentralus'

var name = 'akscluster'
var loadTestName = '${alias}lvluploadtesting'
var vnetName = '${alias}lvlupvnet'
var crName = '${alias}lvlupacr'
var aksRoleAssignmentPullACR = guid(resourceGroup().id, containerRegistry.name, aksCluster.id, 'acrpull')
var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: crName 
  location: location
  dependsOn:[
    aksCluster
  ]
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}


resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: aksVersion
    dnsPrefix: '${name}${alias}'
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 3
        minCount: 2
        maxCount: 5
        maxPods: 50
        enableAutoScaling: true
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
        vnetSubnetID: virtualNetwork.properties.subnets[0].id
      }
    ]
    networkProfile:{
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      outboundType: 'loadBalancer'
      dockerBridgeCidr: '172.17.0.1/16'
    }
  }
}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
    subnets: [
      {
        name: 'aksSubnet'
        properties: {
          addressPrefix: '10.241.0.0/16'
        }
      }
      {
        name: 'aciSubnet'
        properties: {
          addressPrefix: '10.240.0.0/16'
        }
      }
    ]
  }
}

resource assignACRPullToAks 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: aksRoleAssignmentPullACR
  scope: containerRegistry
  properties:{
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleDefinitionId
  }
}

resource loadtesting 'Microsoft.LoadTestService/loadTests@2021-12-01-preview' = {
  name: loadTestName
  location: loadTestingLocation
  properties: {
    
  }
}

output clusterName string = aksCluster.name 
output fqdn string = aksCluster.properties.fqdn
output assignmentNameCalc string = aksRoleAssignmentPullACR
