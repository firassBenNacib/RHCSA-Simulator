# Scenario Tooling

This directory contains the implementation for scenario generation, auditing, smoke tests, and replay verification.

Shared implementation should live in the `rhcsa_scenarios` package. Top-level scripts in this directory are CLI entrypoints.

Compatibility wrappers remain in `host/*.py` for one release so existing commands keep working:

```powershell
python host/audit_scenarios.py
python host/verify_scenario_solutions.py --kind all --audit-only
```

New automation should prefer the `tools/scenarios` entrypoints. Keep the `host/*.py` wrappers working for compatibility until a documented deprecation release removes them.

RHCSA 10 scenario content is generated from `generate_rhcsa10_scenarios.py`:

```powershell
python tools/scenarios/generate_rhcsa10_scenarios.py
python tools/scenarios/generate_scenario_markdown.py
python tools/scenarios/audit_scenarios.py
```

Generated task wording must remain original. Local PDF study material can guide topic coverage, but do not copy exam-dump or commercial-course text into scenarios.
