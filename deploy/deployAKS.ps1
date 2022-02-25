[CmdletBinding()]
param (
    [string]$Location = 'centralus',
    [string]$TemplateFile = '.\deployrg.bicep',
    [string]$TemplateParameterFile = '.\deployrg.parameters.json'
)

New-AzSubscriptionDeployment -Location $Location -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile