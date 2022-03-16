
param location string = resourceGroup().location


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
var kvName = '${alias}lvlupkeyvault'
var aksRoleAssignmentPullACR = guid(resourceGroup().id, containerRegistry.name, aksCluster.id, 'acrpull')
var altRoleAssignmentReadKV = guid(resourceGroup().id, keyvault.id, loadtesting.id, 'reader')
var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','7f951dda-4ed3-4680-a7ca-43fe172d538d')
var readerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','acdd72a7-3385-48ef-bd42-f606fba81ae7')

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

resource NSG 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${alias}AKSNSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allowhttp'
        properties:{ 
          access: 'Allow'
          description: 'Allow port 80 traffic'
          destinationAddressPrefix:'*'
          destinationPortRange: '80'
          direction: 'Inbound'
          priority: 1000
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
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
          networkSecurityGroup: {
            id: NSG.id
          }
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
  identity: {
    type:'SystemAssigned'
  }
  properties: {     
    
  }
}
resource keyvault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: kvName
  location: location 
  properties: {
    accessPolicies: [
    {      
      objectId: loadtesting.identity.principalId
      permissions: {       
       
        secrets: [
          'get'
        ]       
      }
      tenantId: subscription().tenantId
    }
  ]
    
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
  }
}

resource assignALTToKVRead 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: altRoleAssignmentReadKV
  scope: keyvault
  properties:{
    principalId: loadtesting.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: readerRoleDefinitionId
  }
}

output clusterName string = aksCluster.name 
output fqdn string = aksCluster.properties.fqdn
output assignmentNameCalc string = aksRoleAssignmentPullACR
