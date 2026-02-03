# GA-AppLocker Testing Strategy (Behavioral)

This strategy replaces the 1000+ brittle unit tests with a small, high-signal
suite focused on real workflows, critical logic, and performance budgets.

## Principles

- Favor end-to-end behavior over implementation details
- Test what users do, not how code is written
- Keep the default suite fast and deterministic
- Run legacy tests only when investigating regressions

## Test Layers

### 1) Behavioral Workflows (highest value)
- Headless, mock-data workflows that simulate real usage
- No AD/WinRM required
- Validate the complete pipeline:
  Discovery -> Scan -> Rules -> Policy -> Export

### 2) Core Logic (targeted)
- Small set of deterministic tests for:
  - Rule generation selection logic
  - Policy phase enforcement
  - Add/remove rules from policies

### 3) Performance Budgets
- Guardrails for high-impact operations
- Keep thresholds generous to avoid flaky failures

### 4) UI Smoke (optional)
- Minimal checks that panels load and key controls are wired
- Avoid pixel or layout assertions

## What Runs by Default

The default test runner executes only `Tests/Behavioral/**`.
Legacy tests are still available but opt-in.

## Legacy Tests

Legacy tests live under `Tests/Legacy/` and are not run by default.
Use these when diagnosing regressions or validating wide changes.
