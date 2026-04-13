import sys

from verify_scenario_solutions import (
    apply_task_sequence,
    load_manifest,
    run_remote_script,
    run_ps,
    start_or_reset_scenario,
    wait_for_started_scenario,
)


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("usage: _debug_verify_first_task.py <lab|exam> <scenario-id>")

    kind = sys.argv[1]
    scenario_id = sys.argv[2]
    mode = "Lab" if kind == "lab" else "Exam"
    manifest = load_manifest(kind, scenario_id)

    print("start", flush=True)
    started, output = start_or_reset_scenario(scenario_id, mode, 600)
    print(f"started={started}", flush=True)
    print(output[-2000:], flush=True)
    if not started:
        return 1

    print("wait", flush=True)
    wait_for_started_scenario(manifest)

    print("task1", flush=True)
    result = apply_task_sequence(
        manifest,
        kind,
        0,
        0,
        600,
        initial_vm=None,
        initial_user="root",
    )
    print(result, flush=True)

    print("inspect", flush=True)
    if scenario_id == "lab-41-ipv6-networking":
        inspect_proc = run_remote_script(
            "clientvm",
            "root",
            """set -euo pipefail
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 == "eth1" {print $1; found = 1; exit} $2 != "" && $2 != "lo" && first == "" {first = $1} END {if (!found) print first}')"
echo "CONN=$CONN"
nmcli -t -f NAME,UUID,TYPE,DEVICE connection show
nmcli -t -f NAME,UUID,TYPE,DEVICE connection show --active
nmcli -g ipv6.addresses connection show "$CONN"
nmcli -g ipv6.gateway connection show "$CONN"
nmcli -g ipv6.dns connection show "$CONN"
nmcli -g ipv6.method connection show "$CONN"
echo "--eth0--"
nmcli -g ipv6.addresses connection show "eth0" || true
nmcli -g ipv6.gateway connection show "eth0" || true
nmcli -g ipv6.dns connection show "eth0" || true
nmcli -g ipv6.method connection show "eth0" || true
echo "--eth1--"
nmcli -g ipv6.addresses connection show "System eth1" || true
nmcli -g ipv6.gateway connection show "System eth1" || true
nmcli -g ipv6.dns connection show "System eth1" || true
nmcli -g ipv6.method connection show "System eth1" || true
hostnamectl --static
getent hosts servervm.ipv6lab.local || true
""",
            600,
        )
        print(f"inspect_rc={inspect_proc.returncode}", flush=True)
        print(inspect_proc.stdout, flush=True)
        print(inspect_proc.stderr, flush=True)
    elif scenario_id == "lab-48-ssh-key-scp":
        client_proc = run_remote_script(
            "clientvm",
            "root",
            "set -euo pipefail\nid bridge48\ngetent shadow bridge48 | awk -F: '{print $1\":\"$2}'",
            600,
        )
        server_proc = run_remote_script(
            "servervm",
            "root",
            "set -euo pipefail\nid bridge48\ngetent shadow bridge48 | awk -F: '{print $1\":\"$2}'",
            600,
        )
        print(f"client_inspect_rc={client_proc.returncode}", flush=True)
        print(client_proc.stdout, flush=True)
        print(client_proc.stderr, flush=True)
        print(f"server_inspect_rc={server_proc.returncode}", flush=True)
        print(server_proc.stdout, flush=True)
        print(server_proc.stderr, flush=True)
        check1_proc = run_remote_script(
            "clientvm",
            "root",
            """set -euo pipefail
getent passwd bridge48 >/dev/null
getent shadow bridge48 | awk -F: 'length($2)>0 && $2 !~ /^(!!?|\\*|LK|NP)$/'
ssh admin@servervm sudo getent passwd bridge48 >/dev/null
ssh admin@servervm sudo getent shadow bridge48 | awk -F: 'length($2)>0 && $2 !~ /^(!!?|\\*|LK|NP)$/'
""",
            600,
        )
        print(f"check1_inspect_rc={check1_proc.returncode}", flush=True)
        print(check1_proc.stdout, flush=True)
        print(check1_proc.stderr, flush=True)

    print("check1", flush=True)
    proc = run_ps("check", timeout_seconds=600)
    print(f"check_rc={proc.returncode}", flush=True)
    print(proc.stdout, flush=True)
    print(proc.stderr, flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
