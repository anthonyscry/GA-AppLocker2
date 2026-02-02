# Feature: Deploy Edit tab edits Deployment Jobs

## Summary
- Replace Deploy Edit tab behavior so it edits Deployment Jobs (GPOName, Schedule, TargetOUs) when a job is selected.
- Preserve policy metadata editing only when no job is selected (fallback).
- Add UI fields for Job ID and Schedule, plus optional Target OUs.

## Scope and assumptions
- Scope: Deploy panel Edit tab UI + handlers + deployment job update backend + tests.
- Out of scope: job scheduling engine (Schedule remains metadata).
- Assumption: Deployment jobs are stored in %LOCALAPPDATA%\GA-AppLocker\Deployments.

## Acceptance criteria
- [ ] Edit tab shows Job ID, GPO, Schedule, Target OUs when a job is selected in the DataGrid.
- [ ] Saving in Edit tab updates the selected job JSON when Status is Pending.
- [ ] Saving a non-Pending job shows a warning and does not change the job.
- [ ] When no job is selected, Edit tab continues to edit policy metadata.
- [ ] Deployment DataGrid refreshes after save.
- [ ] Pester unit tests cover Update-DeploymentJob and Deploy panel edit flow.

## Architecture diagram

```
Deploy Edit Tab (XAML)
    |
    v
GUI/Panels/Deploy.ps1
    |-- if job selected -> Update-DeploymentJob -> Deployments/{JobId}.json
    `-- else -> Update-Policy -> Policies/{PolicyId}.json
```

## Implementation steps (file-by-file)
1) GA-AppLocker/Modules/GA-AppLocker.Deployment/Functions/Update-DeploymentJob.ps1
   - Implement update for Pending jobs only.
   - Accept JobId (required), GPOName, Schedule, TargetOUs.
   - Write back JSON and log with Write-AppLockerLog.

2) GA-AppLocker/Modules/GA-AppLocker.Deployment/GA-AppLocker.Deployment.psd1
   - Add Update-DeploymentJob to FunctionsToExport.

3) GA-AppLocker/Modules/GA-AppLocker.Deployment/GA-AppLocker.Deployment.psm1
   - Add Update-DeploymentJob to Export-ModuleMember list.

4) GA-AppLocker/GA-AppLocker.psd1 and GA-AppLocker/GA-AppLocker.psm1
   - Add Update-DeploymentJob to root export lists.

5) GA-AppLocker/GUI/MainWindow.xaml
   - Add TxtDeployEditJobId (read-only TextBlock).
   - Add CboDeployEditSchedule (Manual/Immediate/Scheduled).
   - Add TxtDeployEditTargetOUs (optional multi-line textbox).
   - Keep dark theme styles consistent with existing fields.

6) GA-AppLocker/GUI/Panels/Deploy.ps1
   - Update Update-DeployPolicyEditTab to populate job fields when a job is selected.
   - Update Invoke-SaveDeployPolicyChanges to call Update-DeploymentJob when job selected.
   - Keep policy editing as fallback when no job is selected.
   - Refresh DeploymentJobsDataGrid after save.

7) Tests
   - Tests/Unit/Deployment.Tests.ps1: add Update-DeploymentJob cases (Pending only, fields updated).
   - Tests/Unit/GUI.DeployPanel.Tests.ps1: add job-edit wiring tests.
   - Tests/Unit/V1229Session.Tests.ps1: update regex assertions for new Edit tab fields.

## Task list and dependencies
- T1 Backend update function and exports
  - Depends on: none
- T2 XAML edit tab fields
  - Depends on: none
- T3 Deploy panel wiring (populate job fields + save logic)
  - Depends on: T1, T2
- T4 Tests (Deployment, DeployPanel, V1229Session)
  - Depends on: T1, T3

## Test matrix (cases x layers)
| Case | Module unit | GUI unit | XAML/regex | Manual smoke |
|------|-------------|----------|------------|--------------|
| Update Pending job GPOName | Update-DeploymentJob test | DeployPanel test | - | Deploy UI save |
| Update Pending job Schedule | Update-DeploymentJob test | DeployPanel test | - | Deploy UI save |
| Reject non-Pending job | Update-DeploymentJob test | - | - | Deploy UI save |
| Edit tab shows Job ID + Schedule | - | DeployPanel test | V1229Session | Deploy UI open |
| Fallback to policy edit when no job selected | - | DeployPanel test | V1229Session | Deploy UI save |

## Rollout steps
1) Run Pester unit tests: Tests/Unit/Deployment.Tests.ps1 and Tests/Unit/GUI.DeployPanel.Tests.ps1.
2) Run full unit suite if needed: Invoke-Pester -Path Tests/Unit -Output Minimal.
3) Manual smoke: create a Pending job, edit schedule/GPO, save, verify DataGrid updated.

## Rollback steps
- Revert commits for T1-T4 and restore previous Edit tab UI (policy-only).
- Remove Update-DeploymentJob exports from module/root manifests if reverting the backend.

## Notes and unknowns
- There is a duplicate module tree under C:\Projects\GA-AppLocker3\Modules\GA-AppLocker.Deployment. Verify runtime loads the GA-AppLocker\Modules path, not the duplicate.
- Schedule is metadata only; no scheduler exists. Do not add scheduling logic in this change.

## Completion Notes
- T1: Added Update-DeploymentJob function and exports in Deployment and root manifests.
- T2: Added Deploy Edit fields for Job ID, Schedule, and Target OUs in MainWindow.xaml.
- T3: Deploy Edit tab now syncs selected job details and saves updates via Update-DeploymentJob with policy fallback.
- T4: Added Update-DeploymentJob unit tests and Deploy panel/XAML tests for job edit fields.

## Deviations
- None.
