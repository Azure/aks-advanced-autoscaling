targetScope = 'subscription'

param rgname string
param aksClusterName string
param aksVersion string = '1.19.13'
@allowed([
  'eastasia'
  'southeastasia'
  'centralus'
  'eastus'
  'eastus2'
  'westus'
  'northcentralus'
  'southcentralus'
  'northeurope'
  'westeurope'
  'japaneast'
  'brazilsouth'
  'australiaeast'
  'centralindia'
  'canadacentral'
  'uksouth'
  'westcentralus'
  'westus2'
  'francecentral'
])
param location string =  'centralus'

@allowed([
  'australiaeast'
  'eastus'
  'eastus2'
  'northeurope'
  'southcentralus'
])
param loadTestingLocation string = 'southcentralus'


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name:  rgname
  location: location
  properties: {
    
  }
}


module aksCluster './aksCreation.bicep' = {
  scope: rg
  name: 'aksCluster'
  params:{
    name: aksClusterName
    aksVersion: aksVersion
    loadTestingLocation: loadTestingLocation
  }
}
