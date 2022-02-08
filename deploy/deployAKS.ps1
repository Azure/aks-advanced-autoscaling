[CmdletBinding()]
param (
    [string][parameter(Mandatory=$true)]$Location = 'centralus',
    [string][parameter(Mandatory=$true)]$TemplateFile = '.\deployrg.bicep',
    [string]$TemplateParameterFile = '.\deployrg.parameters.json'
)

New-AzSubscriptionDeployment -Location $Location -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile