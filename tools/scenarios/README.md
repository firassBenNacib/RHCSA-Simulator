# Scenario Tooling

This directory contains the implementation for scenario generation, auditing, smoke tests, and replay verification.

Compatibility wrappers remain in `host/*.py` for one release so existing commands keep working:

```powershell
python host/audit_scenarios.py
python host/verify_scenario_solutions.py --kind all --audit-only
```

New automation should call these files directly only when it does not need backwards compatibility.
