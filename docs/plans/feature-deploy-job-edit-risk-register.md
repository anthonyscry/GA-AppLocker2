# Risk Register: Deploy Job Edit

| ID | Risk | Impact | Likelihood | Mitigation | Detection |
|----|------|--------|------------|------------|-----------|
| R1 | Wrong module path used (duplicate module tree under C:\Projects\GA-AppLocker3\Modules) | Feature appears to work in dev but not in runtime | Medium | Verify module base path after Import-Module and update only GA-AppLocker\Modules tree | `Get-Module GA-AppLocker` and confirm ModuleBase path |
| R2 | Edit tab UI regressions (policy edit breaks) | Users lose ability to edit policy metadata | Medium | Keep fallback behavior when no job selected; add unit test | GUI.DeployPanel.Tests + manual smoke |
| R3 | Update-DeploymentJob called for non-Pending jobs | Jobs modified mid-deployment | Low | Enforce Pending-only in Update-DeploymentJob and show warning | Deployment.Tests + manual smoke |
| R4 | XAML/regex tests become brittle | Test failures after UI layout changes | Medium | Update V1229Session.Tests with stable element names and minimal regex | Pester V1229Session.Tests |
| R5 | Schedule semantics confusion | Users expect auto scheduling | Medium | UI text and docs clarify Schedule is metadata only | Manual UAT review |
