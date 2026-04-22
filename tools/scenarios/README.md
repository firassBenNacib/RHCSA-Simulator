# Scenario Tooling

This directory contains the implementation for scenario generation, auditing, smoke tests, and replay verification.

Shared implementation should live in the `rhcsa_scenarios` package. Top-level scripts in this directory are CLI entrypoints.

Use the `tools/scenarios` entrypoints directly:

RHCSA 10 scenario content is generated from `generate_rhcsa10_scenarios.py`:

```powershell
python tools/scenarios/verify_scenario_solutions.py --kind all --audit-only
python tools/scenarios/generate_rhcsa10_scenarios.py
python tools/scenarios/generate_scenario_markdown.py
python tools/scenarios/audit_scenarios.py
```

Generated task wording must remain original. Local PDF study material can guide topic coverage, but do not copy exam-dump or commercial-course text into scenarios.
