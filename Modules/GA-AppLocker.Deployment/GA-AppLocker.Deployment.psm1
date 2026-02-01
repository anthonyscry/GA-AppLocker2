# Standard module loader pattern for GA-AppLocker sub-modules
$ErrorActionPreference = 'Stop'
$global:GA_ModulePath = Split-Path $MyInvocation.MyCommand.Definition
$global:GA_ModuleRoot = Join-Path -Path $global:GA_ModulePath -ChildPath '..'

# Load functions
. "$($global:GA_ModuleRoot)\Functions\Update-DeploymentJob.ps1"

# Finalize export
Export-ModuleMember -FunctionNames Update-DeploymentJob