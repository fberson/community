param location string = 'westeurope'
param vmSizes array

param adminUsername string
@secure()
param adminPassword string

param obuxEmail string = 'you@domain.com'
param obuxShareData bool = true
param obuxInsightInterval int = 5
param sourceIpAddress string

@minLength(3)
@maxLength(12)
param vmNameprefix string = 'obux-vm'

param obuxBenchmarkNameprefix string = 'run-'

param vnetAddressPrefixes array = ['10.0.0.0/16']
param subnetAddressPrefix string = '10.0.0.0/24'

// Define obuxShareDataStr based on obuxShareData parameter
var obuxShareDataStr = obuxShareData ? 'true' : 'false'

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: '${vmNameprefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

// Network Security Group (NSG) and Inbound Rule for RDP Access
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: '${vmNameprefix}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: sourceIpAddress
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Loop to create public IPs for each VM
resource publicIPs 'Microsoft.Network/publicIPAddresses@2022-11-01' = [for (vmSize, i) in vmSizes: {
  name: '${vmNameprefix}-${i}-pip'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]

// Loop to create network interfaces for each VM
resource nic 'Microsoft.Network/networkInterfaces@2022-11-01' = [for (vmSize, i) in vmSizes: {
  name: '${vmNameprefix}-${i}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPs[i].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}]

// Loop to deploy multiple VMs based on the vmSizes array
resource vms 'Microsoft.Compute/virtualMachines@2023-03-01' = [for (vmSize, i) in vmSizes: {
  name: '${vmNameprefix}-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${vmNameprefix}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
  }
}]

// Updated storage account name to ensure it meets Azure's naming requirements
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'obuxvmstorage'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource storageBlobContributorRole 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
name: guid(storageAccount.id, 'StorageBlobDataContributor', replace(deployer().userPrincipalName, '@', '-'))
  scope: storageAccount
  properties: {
    principalId: deployer().objectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalType: 'User'
  }
}


// Ensure the `blobServices` resource is explicitly created
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
}

// Ensure the `containers` resource is explicitly created
resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  parent: blobServices
  name: 'results'
  properties: {
    publicAccess: 'None'
  }
}

// Updated the deployment name to accept a timestamp parameter
param deploymentTimestamp string

// SAS Token Generation Module
module generateSasToken './generateSasToken.bicep' = {
  name: 'generateSasToken-${deploymentTimestamp}'
  params: {
    storageAccountName: storageAccount.name
    expiryDate: '2026-06-03T00:00:00Z' // 1 year from now
  }
}

// Custom Script Extension to download and run OBUX securely with commandToExecute and SAS token in protectedSettings
resource obuxExtensions 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = [for (vmSize, i) in vmSizes: {
  name: 'obuxCustomScript-${i}'
  parent: vms[i]
  location: location
  tags: {
    displayName: 'OBUX Benchmark Extension'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/fberson/community/refs/heads/main/obux/deployObux.ps1'
      ]
    }
    protectedSettings: {
      commandToExecute: format('powershell -ExecutionPolicy Unrestricted -File deployObux.ps1 -email "{0}" -benchmark "{1}" -sharedata "{2}" -insightinterval {3} -storageAccount "{4}" -containerName "results" -sasToken "{5}"',
        obuxEmail,
        '${obuxBenchmarkNameprefix}-${i}-${vmSize}',
        obuxShareDataStr,
        obuxInsightInterval,
        storageAccount.name,
        generateSasToken.outputs.sasToken
      )
    }
  }
}]


