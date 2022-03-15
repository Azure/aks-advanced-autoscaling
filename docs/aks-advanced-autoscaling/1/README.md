# AKS Autoscaling and Performance Deployment


# Parameters


Parameter Name | Description 
-------------- | ----------- 
 rgname | this parameter is the name of the resource group - the template is a subscription scope which deploys a resource group with all of the necessary resources 
 alias | this parameter is used to create a unique name for your resources and dns prefix for your aks cluster 
 aksversion | this parameter is for you to provide what version of kubernetes is installed on the cluster 
 location | this parameter is the azure datacenter that the resource group and resources will be created in - with the exception of the azure load testing resource which is further limited.  the allowed values for this parameter are datacenters that support aks 
 loadTestingLocation | the datacenter for load testing - allowed values are datacenters that support the load testing resource 

To deploy the infrastructure for this exercise there are 2 options:

##Option 1

Click this button and provide the parameters in the portal - see parameters below for an explanation of the template parameters

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Faks-advanced-autoscaling%2Fmodule1%2Fdeploy%2Fdeployrg.json)

### About the button
    In order to create a Deploy to Azure button, you create a link to https://portal.azure.com/#create/Microsoft.Template/uri/<html encoded url to the file you wan to deploy>
    because .bicep files are currently not supported for remote deployment you must build your bicep file (transpose it into json) using the bicep CLI - bicep build <filename> which will output a monolithic JSON ARM template. 
    this is the file that is linked to in the button above
    if you were to add resources to the bicep file, you would then need to run bicep build on the file and replace the deployrg.json file with the newly built one
        
* this would require you to have the bicep cli installed on your machine [Install bicep tools](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
## Option 2
you can [clone the repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) and use az powershell or az cli to deploy the bicep template from your local machine.
you must have the proper cli and or powershell 
[Install Azure CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
[Install Azure Powershell](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-powershell)
