# Scenario Tooling

This directory contains the implementation for scenario generation, auditing, smoke tests, and replay verification.

Shared implementation should live in the `rhcsa_scenarios` package. Top-level scripts in this directory are CLI entrypoints.

Use the `tools/scenarios` entrypoints directly:

RHCSA 10 scenario content is generated from `generate_rhcsa10_scenarios.py`. After regenerating scenarios and Markdown, run both fast validation commands:

```powershell
<python> .\tools\scenarios\generate_rhcsa10_scenarios.py
<python> .\tools\scenarios\generate_scenario_markdown.py
<python> .\tools\scenarios\audit_scenarios.py
<python> .\tools\scenarios\verify_scenario_solutions.py --kind all --track all --audit-only
```

Replace `<python>` with the Python launcher available on your machine, such as `python`, `python3.13.exe`, or `py -3.13`.

`--audit-only` checks replay command structure only. Keep `audit_scenarios.py` in the workflow because it enforces metadata, target balance, generated Markdown consistency, and scenario quality guardrails.

Generated task wording must remain original. Local PDF study material can guide topic coverage, but do not copy exam-dump or commercial-course text into scenarios.
