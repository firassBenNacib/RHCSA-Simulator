GO ?= go
PYTHON ?= python3

.PHONY: test ci go-test go-vet go-build python-compile python-test scenario-audit scenario-replay-audit vagrant-validate release-snapshot clean

test: go-test go-vet go-build python-compile python-test scenario-audit scenario-replay-audit

ci: test vagrant-validate

go-test:
	$(GO) test ./...

go-vet:
	$(GO) vet ./...

go-build:
	$(GO) build ./cmd/rhcsa-tui

python-compile:
	$(PYTHON) -m py_compile tools/scenarios/*.py tools/scenarios/rhcsa_scenarios/*.py tools/scenarios/tests/*.py

python-test:
	$(PYTHON) -m unittest discover tools/scenarios/tests

scenario-audit:
	$(PYTHON) tools/scenarios/audit_scenarios.py

scenario-replay-audit:
	$(PYTHON) tools/scenarios/verify_scenario_solutions.py --kind all --track all --audit-only

vagrant-validate:
	vagrant validate

release-snapshot:
	goreleaser release --snapshot --clean

clean:
	rm -rf .build dist coverage.out
	rm -f rhcsa-tui rhcsa-tui.exe
