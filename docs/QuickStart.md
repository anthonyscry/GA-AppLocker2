# GA-AppLocker Quick Start Guide

Get AppLocker policies deployed to your enterprise in 5 steps.

---

## Prerequisites

Before you begin, ensure:

- [ ] Windows 10 or Server 2019+ with PowerShell 5.1+
- [ ] Domain-joined machine with RSAT installed
- [ ] Domain Admin or equivalent credentials for GPO management
- [ ] WinRM enabled on target machines (for remote scanning)

---

## Step 1: Launch the Dashboard

Open PowerShell as Administrator and run:

```powershell
cd C:\Path\To\GA-AppLocker2
.\Run-Dashboard.ps1
```

The dark-themed dashboard will appear with 7 navigation panels on the left.

---

## Step 2: Configure Credentials (Settings Panel)

1. Click **Settings** in the left navigation
2. Under "Credential Profiles", click **Add Profile**
3. Create tiered credentials:
   - **T0 - Domain Controllers**: Highest privilege (Domain Admin)
   - **T1 - Servers**: Server admin credentials
   - **T2 - Workstations**: Workstation admin credentials
4. Click **Test** to verify each credential works

> **Security Note**: Credentials are stored locally using DPAPI encryption.

---

## Step 3: Discover Network Assets (Discovery Panel)

1. Click **Discovery** in the left navigation
2. Click **Refresh Domain Info** to load your AD forest
3. Expand the OU tree and select target OUs
4. Click **Get Computers** to enumerate machines
5. Click **Test Connectivity** to verify WinRM access

> **Tip**: Green checkmarks indicate successful connectivity.

---

## Step 4: Scan for Artifacts (Scanner Panel)

1. Click **Scanner** in the left navigation
2. Select target machines from the list
3. Configure scan options:
   - **Scan Paths**: e.g., `C:\Program Files`, `C:\Program Files (x86)`
   - **Include DLLs**: Check if you need DLL rules
   - **Recursive**: Scan subdirectories
4. Click **Start Scan**
5. Wait for scan completion (progress bar shows status)

> **Performance**: Scanning 1000 files takes approximately 2-5 minutes per machine.

---

## Step 5: Generate Rules (Rules Panel)

### Option A: Rule Generation Wizard (Recommended)

1. Click **Rules** in the left navigation
2. Click **Generate Rules** button
3. Follow the 3-step wizard:
   - **Step 1**: Select artifacts to include
   - **Step 2**: Configure rule options (Publisher/Hash/Path)
   - **Step 3**: Review and generate
4. Click **Generate** to create rules

### Option B: Manual Rule Creation

1. Right-click any artifact in the Scanner panel
2. Select **Create Rule** from context menu
3. Choose rule type: Publisher (recommended), Hash, or Path

### Review Rules

- **Pending**: Needs review
- **Approved**: Ready for policy
- **Rejected**: Excluded from policies

Use the context menu (right-click) to approve/reject rules in bulk.

---

## Step 6: Build Policy (Policy Panel)

1. Click **Policy** in the left navigation
2. Click **New Policy**
3. Configure:
   - **Name**: e.g., "Workstation-Baseline-2026"
   - **Enforcement Mode**: Start with "Audit Only"
   - **Phase**: Select deployment phase (1-4)
4. Click **Add Rules** and select approved rules
5. Click **Export to XML** to generate AppLocker policy

---

## Step 7: Deploy to GPO (Deployment Panel)

1. Click **Deployment** in the left navigation
2. Select policy to deploy
3. Configure target:
   - **GPO Name**: Create new or use existing
   - **Target OU**: Where to link the GPO
4. Click **Deploy**
5. Monitor progress in the deployment log

> **Important**: Always test in "Audit Only" mode first!

---

## Deployment Phases

GA-AppLocker uses a phased approach to minimize disruption:

| Phase | Mode | Description |
|-------|------|-------------|
| 1 | Audit Only | Log violations, no blocking |
| 2 | Audit Only | Extended monitoring period |
| 3 | Audit Only | Final validation before enforcement |
| 4 | Enforce | Block unauthorized applications |

**Recommendation**: Spend at least 2 weeks in each audit phase before progressing.

---

## Common Workflows

### Adding a New Application

1. Install the application on a test machine
2. Run a local scan: **Scanner** → **Scan Local**
3. Find the new artifacts in the list
4. Right-click → **Create Rule**
5. Approve the rule
6. Add to existing policy
7. Re-deploy policy

### Investigating Blocked Applications

1. Check AppLocker event logs: **Scanner** → **Get Event Logs**
2. Find the blocked file hash or publisher
3. Create an allow rule for legitimate applications
4. Add to policy and redeploy

### Bulk Rule Operations

1. In **Rules** panel, use the filter to find rules
2. Select multiple rules (Ctrl+Click or Shift+Click)
3. Right-click → **Approve Selected** or **Reject Selected**

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| F5 | Refresh current panel |
| Ctrl+S | Save current state |
| Escape | Cancel current operation |

---

## Troubleshooting

### "WinRM connection failed"
- Ensure WinRM is enabled: `winrm quickconfig`
- Check firewall rules (TCP 5985/5986)
- Verify credentials have remote admin rights

### "GPO not found"
- Ensure RSAT is installed
- Verify account has GPO management permissions
- Check domain connectivity

### "Rule generation slow"
- Use the Rule Generation Wizard for batch processing
- The old method processes ~2 rules/second
- The wizard processes 10-20 rules/second

### Application Data Location

All data is stored in:
```
%LOCALAPPDATA%\GA-AppLocker\
├── config.json         # Application settings
├── session.json        # UI state (auto-saved)
├── Credentials\        # Encrypted credentials
├── Scans\             # Scan results
├── Rules\             # Generated rules
├── Policies\          # Built policies
└── Logs\              # Application logs
```

---

## Getting Help

- **Logs**: Check `%LOCALAPPDATA%\GA-AppLocker\Logs\` for detailed logs
- **Developer Guide**: See `CLAUDE.md` in the project root
- **Full Spec**: See `docs\GA-AppLocker-Full-Specification.md`

---

## Next Steps

After completing this quick start:

1. Review the full specification for advanced features
2. Set up automated scans on a schedule
3. Create baseline policies for different machine types
4. Document your organization's AppLocker rule approval process
