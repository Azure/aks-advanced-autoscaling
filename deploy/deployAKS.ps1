[CmdletBinding()]
param (
    [string]$Location = 'eastus2',
    [string]$TemplateFile = '.\deployrg.bicep',
    [string]$TemplateParameterFile = '.\deployrg.parameters.json'
)

New-AzSubscriptionDeployment -Location $Location -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile