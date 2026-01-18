# GA-AppLocker Development Guide

This document provides technical details for developers working on the GA-AppLocker codebase.

## Architecture Overview

### Module Structure

GA-AppLocker follows a modular architecture with 7 specialized sub-modules:

```
GA-AppLocker (Parent Module)
├── GA-AppLocker.Core         - Foundation: logging, config, prerequisites
├── GA-AppLocker.Discovery    - AD integration: domain, OU, machine discovery
├── GA-AppLocker.Credentials  - Secure credential storage with DPAPI
├── GA-AppLocker.Scanning     - Artifact collection from local/remote machines
├── GA-AppLocker.Rules        - AppLocker rule generation and management
├── GA-AppLocker.Policy       - Policy composition and targeting
└── GA-AppLocker.Deployment   - GPO creation and policy deployment
```

### Standard Return Pattern

**All functions MUST return a consistent hashtable structure:**

```powershell
@{
    Success = $true | $false
    Data    = <result object or array>
    Error   = "Error message if Success is $false"
    Message = "Optional success message"
}
```

Example:
```powershell
function Get-Something {
    try {
        $result = # ... do work
        return @{
            Success = $true
            Data    = $result
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}
```

### UI Architecture

The WPF UI follows a **central dispatcher pattern**:

1. **MainWindow.xaml** - Defines all visual elements and styles
2. **MainWindow.xaml.ps1** - Contains all event handlers and UI logic

Key patterns:
- `Invoke-ButtonAction` - Central dispatcher for all button clicks
- `Set-ActivePanel` - Manages panel visibility (navigation)
- `Initialize-*Panel` - Each panel has its own initialization function
- Global functions (prefixed with `global:`) for closures that need module access

```powershell
# Button dispatcher pattern
function global:Invoke-ButtonAction {
    param([string]$Action)
    switch ($Action) {
        'NavDashboard' { Set-ActivePanel -PanelName 'PanelDashboard' }
        'StartScan'    { Invoke-StartArtifactScan -Window $win }
        # ... more actions
    }
}
```

## Coding Standards

### Function Requirements

1. **CmdletBinding**: Always use `[CmdletBinding()]`
2. **Parameter Validation**: Use `[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, etc.
3. **Try/Catch**: Wrap all I/O operations
4. **Comment-Based Help**: Include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`

```powershell
function New-ExampleRule {
    <#
    .SYNOPSIS
        Creates a new example rule.
    
    .DESCRIPTION
        Detailed description of what this function does.
    
    .PARAMETER Name
        The name of the rule.
    
    .EXAMPLE
        New-ExampleRule -Name "TestRule"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )
    
    try {
        # Implementation
        return @{ Success = $true; Data = $result }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Functions | Verb-Noun | `Get-PolicyTarget`, `New-DeploymentJob` |
| Variables | camelCase | `$policyResult`, `$targetOUs` |
| Script Variables | $script: prefix | `$script:CurrentFilter` |
| Global Variables | $global: prefix | `$global:GA_MainWindow` |
| Constants | UPPER_CASE | `$APP_VERSION` |

### Approved Verbs

Use standard PowerShell approved verbs:
- **Get** - Retrieve data
- **Set** - Modify data
- **New** - Create new item
- **Remove** - Delete item
- **Test** - Validate/check
- **Start/Stop** - Begin/end processes
- **Export/Import** - File operations
- **Add/Remove** - Collection operations

## Adding a New Module

1. Create the module directory:
```
GA-AppLocker/Modules/GA-AppLocker.NewModule/
├── GA-AppLocker.NewModule.psd1
├── GA-AppLocker.NewModule.psm1
└── Functions/
    ├── Function1.ps1
    └── Function2.ps1
```

2. Create the manifest (`.psd1`):
```powershell
@{
    RootModule        = 'GA-AppLocker.NewModule.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '<new-guid>'
    FunctionsToExport = @('Function1', 'Function2')
}
```

3. Create the module loader (`.psm1`):
```powershell
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$FunctionsPath = Join-Path $ModulePath 'Functions'

Get-ChildItem -Path $FunctionsPath -Filter '*.ps1' -File | ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function @('Function1', 'Function2')
```

4. Add to parent module manifest (`GA-AppLocker.psd1`):
```powershell
NestedModules = @(
    # ... existing modules
    'Modules\GA-AppLocker.NewModule\GA-AppLocker.NewModule.psd1'
)

FunctionsToExport = @(
    # ... existing functions
    'Function1',
    'Function2'
)
```

5. Add to parent module exports (`GA-AppLocker.psm1`):
```powershell
Export-ModuleMember -Function @(
    # ... existing functions
    'Function1',
    'Function2'
)
```

## Adding a New UI Panel

1. **Add XAML** in `MainWindow.xaml`:
```xml
<Grid x:Name="PanelNewFeature" Visibility="Collapsed">
    <!-- Panel content -->
</Grid>
```

2. **Add navigation button** in sidebar:
```xml
<Button x:Name="NavNewFeature" 
        Style="{StaticResource NavButtonStyle}"
        Content="&#x1F4CB;  New Feature"/>
```

3. **Add to dispatcher** in `MainWindow.xaml.ps1`:
```powershell
switch ($Action) {
    'NavNewFeature' { Set-ActivePanel -PanelName 'PanelNewFeature' }
}
```

4. **Add panel list** for navigation:
```powershell
$allPanels = @(
    'PanelDashboard', 'PanelDiscovery', 'PanelScanner',
    'PanelRules', 'PanelPolicy', 'PanelDeploy', 'PanelSettings',
    'PanelNewFeature'  # Add new panel
)
```

5. **Create initialization function**:
```powershell
function Initialize-NewFeaturePanel {
    param([System.Windows.Window]$Window)
    # Wire up event handlers
}
```

6. **Call initialization** in `Initialize-MainWindow`:
```powershell
try {
    Initialize-NewFeaturePanel -Window $Window
    Write-Log -Message 'NewFeature panel initialized'
}
catch {
    Write-Log -Level Error -Message "NewFeature panel init failed: $($_.Exception.Message)"
}
```

## Testing

### Running Tests
```powershell
.\Test-AllModules.ps1
```

### Adding New Tests

Add tests to `Test-AllModules.ps1` following this pattern:

```powershell
# Test: Description of what's being tested
try {
    $result = Your-Function -Param "value"
    $hasResult = $result.Success -eq $true
    Write-TestResult -TestName "Your-Function" -Passed $hasResult -Message "Description"
}
catch {
    Write-TestResult -TestName "Your-Function" -Passed $false -Message "Exception" -Details $_.Exception.Message
}
```

### Test Categories

| Category | Tests |
|----------|-------|
| Core | 5 tests |
| Discovery | 4 tests |
| Credentials | 6 tests |
| Scanning | 7 tests |
| Rules | 5 tests |
| Policy | 6 tests |
| Deployment | 6 tests |
| GUI | 5 tests |
| **Total** | **44 tests** |

## Data Storage

All data is stored in `%LOCALAPPDATA%\GA-AppLocker\`:

| Directory | Purpose | Format |
|-----------|---------|--------|
| `/` | Root config | `config.json` |
| `Credentials/` | Encrypted credentials | `{name}.json` (DPAPI) |
| `Scans/` | Scan results | `{guid}.json` |
| `Rules/` | Generated rules | `{guid}.json` |
| `Policies/` | Policy definitions | `{guid}.json` |
| `Deployments/` | Deployment jobs | `{guid}.json` |
| `DeploymentHistory/` | Deployment logs | `{guid}.json` |
| `Logs/` | Application logs | `GA-AppLocker_{date}.log` |

## Debugging

### Enable Verbose Logging
```powershell
$VerbosePreference = 'Continue'
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force
```

### Check Logs
```powershell
$logPath = Join-Path (Get-AppLockerDataPath) 'Logs'
Get-ChildItem $logPath | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

### Test Individual Functions
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

# Test a function
$result = Get-DomainInfo
$result | ConvertTo-Json -Depth 3
```

## Common Issues

### "Function not found in closure"
**Problem**: Button click handlers can't access module functions.
**Solution**: Make the function global with `function global:FunctionName`.

### "XAML parsing error"
**Problem**: Missing style or resource reference.
**Solution**: Ensure all `StaticResource` references exist in `Window.Resources`.

### "Module not loading"
**Problem**: Nested module path incorrect.
**Solution**: Check `NestedModules` paths in `GA-AppLocker.psd1` use backslashes.

## Performance Tips

1. **Avoid DoEvents()** - Use sparingly, only for progress updates
2. **Limit recursion** - Use `MaxDepth` parameter in scanning
3. **Batch operations** - Group file writes where possible
4. **Lazy loading** - Don't load all data on panel init, load on demand

## Security Considerations

1. **Credentials** - Always use DPAPI encryption via `New-CredentialProfile`
2. **No plaintext** - Never store passwords in config files
3. **Validate input** - Use `[ValidateSet()]` and `[ValidatePattern()]`
4. **Principle of least privilege** - Request only necessary permissions
5. **Audit logging** - Log all security-relevant operations
