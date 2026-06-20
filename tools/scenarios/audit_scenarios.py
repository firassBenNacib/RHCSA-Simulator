#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from rhcsa_scenarios.targets import VALID_SCOPES, VALID_TARGETS, normalize_scope, normalize_target, scope_from_targets


ROOT = Path(__file__).resolve().parents[2]
SCENARIOS_DIR = ROOT / "scenarios"
DIRECT_SUDOERS_RE = re.compile(r"(?<!\S)/etc/sudoers(?!\.d(?:/|\b))")
EXAM_SIMILARITY_REPORT_LIMIT = 3
SIMILARITY_STOP_WORDS = {
    "the",
    "and",
    "for",
    "from",
    "with",
    "into",
    "that",
    "this",
    "must",
    "should",
    "client",
    "server",
    "configure",
    "create",
    "install",
    "remove",
    "enable",
    "start",
    "persistent",
    "persistently",
    "using",
    "following",
    "ipaddr",
    "namevalue",
    "pathvalue",
    "sizevalue",
}


@dataclass
class Finding:
    path: Path
    message: str


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def flatten_strings(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        result: list[str] = []
        for item in value:
            result.extend(flatten_strings(item))
        return result
    return [str(value)]


def scenario_text(scenario: dict[str, Any]) -> str:
    text_parts = [
        scenario.get("title", ""),
        scenario.get("description", ""),
    ]
    content = scenario.get("content", {})
    for mode in ("lab", "exam"):
        if mode not in content:
            continue
        block = content[mode]
        for key in ("tasks", "task_titles", "solution_commands", "hints", "solution_outline", "checks"):
            value = block.get(key, [])
            if isinstance(value, list):
                text_parts.extend(flatten_strings(value))
    return "\n".join(text_parts)


def authored_text(scenario: dict[str, Any]) -> str:
    text_parts = [
        scenario.get("title", ""),
        scenario.get("description", ""),
    ]
    content = scenario.get("content", {})
    for mode in ("lab", "exam"):
        if mode not in content:
            continue
        block = content[mode]
        for key in ("tasks", "task_titles", "solution_commands", "hints", "solution_outline"):
            value = block.get(key, [])
            if isinstance(value, list):
                text_parts.extend(flatten_strings(value))
    return "\n".join(text_parts)


def has_pattern(text: str, *patterns: str) -> bool:
    lowered = text.lower()
    return any(re.search(pattern, lowered, re.I) for pattern in patterns)


def task_lengths_ok(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    tracks = scenario.get("tracks") or ["rhcsa9"]
    if not isinstance(tracks, list) or not tracks:
        findings.append(Finding(path, "tracks must be a non-empty list when present"))
    else:
        normalized_tracks = {str(track).strip().lower().replace("-", "").replace("_", "") for track in tracks}
        if not normalized_tracks <= {"rhcsa9", "rhcsa10"}:
            findings.append(Finding(path, "tracks may only contain rhcsa9 or rhcsa10"))

    rhel_major = scenario.get("rhel_major", 9)
    if rhel_major not in (9, 10):
        findings.append(Finding(path, "rhel_major must be 9 or 10"))

    content = scenario["content"]
    if "lab" in content:
        lab = content["lab"]
        tasks = lab["tasks"]
        expected = len(tasks)
        for key in ("task_titles", "task_points", "solution_commands"):
            if len(lab[key]) != expected:
                findings.append(Finding(path, f"lab field '{key}' length does not match tasks"))
        for key in ("task_targets", "solution_targets"):
            if key in lab and len(lab[key]) != expected:
                findings.append(Finding(path, f"lab field '{key}' length does not match tasks"))
        if "check_targets" in lab and len(lab["check_targets"]) != len(lab.get("checks", [])):
            findings.append(Finding(path, "lab field 'check_targets' length does not match checks"))
    if "exam" in content:
        exam = content["exam"]
        tasks = exam["tasks"]
        expected = len(tasks)
        for key in ("task_titles", "task_points", "solution_commands"):
            if len(exam[key]) != expected:
                findings.append(Finding(path, f"exam field '{key}' length does not match tasks"))
        for key in ("task_targets", "solution_targets"):
            if key in exam and len(exam[key]) != expected:
                findings.append(Finding(path, f"exam field '{key}' length does not match tasks"))
        if "check_targets" in exam and len(exam["check_targets"]) != len(exam.get("checks", [])):
            findings.append(Finding(path, "exam field 'check_targets' length does not match checks"))
        if len(tasks) not in (22, 23):
            findings.append(Finding(path, "exam must contain 22 or 23 tasks"))
        if sum(int(point) for point in exam["task_points"]) != 100:
            findings.append(Finding(path, "exam task points must sum to 100"))


def audit_identity(path: Path, scenario: dict[str, Any], seen_ids: dict[str, Path], findings: list[Finding]) -> None:
    scenario_id = str(scenario.get("id", "")).strip()
    if not scenario_id:
        findings.append(Finding(path, "scenario id must be present"))
        return
    if path.parent.name != scenario_id:
        findings.append(Finding(path, f"scenario id '{scenario_id}' must match directory '{path.parent.name}'"))
    previous = seen_ids.get(scenario_id)
    if previous is not None:
        findings.append(Finding(path, f"duplicate scenario id '{scenario_id}' also used by {previous.relative_to(ROOT)}"))
    else:
        seen_ids[scenario_id] = path


def audit_solution_style(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    content = scenario["content"]["lab" if "lab" in scenario["content"] else "exam"]
    tasks_text = "\n".join(content["tasks"])
    solutions = content["solution_commands"]
    combined_solution_text = "\n".join(flatten_strings(solutions))

    useradd_with_home = re.finditer(r"useradd\b[^\n#]*\s-m(?:\s|$)([^\n]*)", combined_solution_text)
    for match in useradd_with_home:
        command_tail = match.group(0)
        username_match = re.search(r"useradd\b[^\n#]*\s([a-z_][a-z0-9_-]*)\s*$", command_tail, re.I)
        username = username_match.group(1) if username_match else ""
        home_related = False
        if username:
            context = tasks_text + "\n" + combined_solution_text
            home_related = any(
                re.search(pattern, context, re.I)
                for pattern in (
                    rf"/home/{re.escape(username)}\b",
                    rf"{re.escape(username)}/\.ssh\b",
                    rf"runuser\s+-l\s+{re.escape(username)}\b",
                    rf"su\s+-\s+{re.escape(username)}\b",
                    rf"loginctl\b[^\n]*\b{re.escape(username)}\b",
                    rf"crontab\b[^\n]*-u\s+{re.escape(username)}\b",
                    rf"ssh-copy-id\b[^\n]*\b{re.escape(username)}@",
                    rf"ssh\b[^\n]*\b{re.escape(username)}@",
                    r"systemctl\s+--user\b",
                    r"\.bash_(profile|rc)\b",
                    r"\bpodman\b",
                    r"passwordless ssh",
                    r"ssh key",
                    r"home directory",
                )
            )
        if not home_related:
            findings.append(Finding(path, f"possible unnecessary useradd -m for '{username or 'unknown user'}'"))

    created_users = set(re.findall(r"\buseradd\b[^\n#]*\s([a-z_][a-z0-9_-]*)\s*$", combined_solution_text, re.M | re.I))
    for username in sorted(created_users):
        if re.search(rf"\busermod\s+-aG\b[^\n]*\b{re.escape(username)}\b", combined_solution_text):
            findings.append(Finding(path, f"usermod -aG used after creating user '{username}'"))

    if DIRECT_SUDOERS_RE.search(combined_solution_text) and not DIRECT_SUDOERS_RE.search(tasks_text):
        findings.append(Finding(path, "solution edits /etc/sudoers directly without task requiring it"))


def audit_target_metadata(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    content = scenario.get("content", {})
    for mode in ("lab", "exam"):
        block = content.get(mode)
        if not isinstance(block, dict):
            continue
        tasks = block.get("tasks", [])
        checks = block.get("checks", [])
        for key, expected in (("task_targets", len(tasks)), ("solution_targets", len(tasks)), ("check_targets", len(checks))):
            values = block.get(key)
            if not isinstance(values, list):
                findings.append(Finding(path, f"{mode} must include {key} metadata"))
                continue
            if len(values) != expected:
                findings.append(Finding(path, f"{mode} {key} length must be {expected}"))
                continue
            invalid = sorted({str(value) for value in values if normalize_target(value, default="") not in VALID_TARGETS})
            if invalid:
                findings.append(Finding(path, f"{mode} {key} has invalid target(s): {', '.join(invalid)}"))

        task_targets = block.get("task_targets", [])
        if isinstance(task_targets, list) and len(task_targets) == len(tasks):
            for index, (task, target) in enumerate(zip(tasks, task_targets), start=1):
                task_text = str(task)
                normalized_target = normalize_target(target, default="")
                leading_target = re.match(r"^\s*On\s+(client|server)\b", task_text, re.I)
                if leading_target and normalized_target in {"client", "server"}:
                    text_target = leading_target.group(1).lower()
                    if text_target != normalized_target:
                        findings.append(Finding(path, f"{mode} task {index} text says {text_target} but task_targets says {normalized_target}"))
                if normalized_target == "both" and not re.search(r"\bclient\b[\s\S]*\bserver\b|\bserver\b[\s\S]*\bclient\b", task_text, re.I):
                    findings.append(Finding(path, f"{mode} task {index} task_targets says both but task text does not mention both systems"))

        if mode == "lab":
            raw_scope = scenario.get("scope")
            scope = normalize_scope(raw_scope, default="")
            if raw_scope is None:
                findings.append(Finding(path, "lab scenario must include scope metadata"))
            elif scope not in VALID_SCOPES:
                findings.append(Finding(path, f"lab scope has invalid value: {raw_scope}"))
            else:
                expected_scope = scope_from_targets(
                    block.get("task_targets", []),
                    requires_server=bool(scenario.get("flags", {}).get("requires_server", False)),
                )
                if scope != expected_scope:
                    findings.append(Finding(path, f"lab scope should be {expected_scope}, not {scope}"))

        if mode in {"lab", "exam"}:
            for index, task in enumerate(tasks, start=1):
                if not re.match(r"^\s*On\s+(client|server)\b", str(task)):
                    findings.append(Finding(path, f"{mode} task {index} must begin with 'On client' or 'On server'"))


def audit_wording_style(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    text = scenario_text(scenario)
    if re.search(r"\bRHCSA style\b", text, re.I):
        findings.append(Finding(path, "avoid generic 'RHCSA style' wording"))
    if re.search(r"\bDNS Server\s*:", text, re.I):
        findings.append(Finding(path, "use 'DNS:' for resolver settings instead of 'DNS Server:'"))
    for line in text.splitlines():
        normalized = line.strip()
        if not normalized:
            continue
        if re.search(r"\b(exact|same|official)\b.{0,50}\b(real\s+)?(exam|red hat|rhcsa)\b.{0,50}\b(answer|solution|question)s?\b", normalized, re.I):
            if not re.search(r"\b(not|never|avoid|without|must not|do not|does not)\b", normalized, re.I):
                findings.append(Finding(path, "avoid claiming exact or official real exam answers"))
                break
        if re.search(r"\b(real\s+exam|exam\s+dump)s?\b", normalized, re.I):
            if not re.search(r"\b(not|never|avoid|without|must not|do not|does not|copied|copy)\b", normalized, re.I):
                findings.append(Finding(path, "avoid wording that suggests copied real exam material"))
                break
    if re.search(r"\b(And|With|Of|To|From|For|On|In)\b", str(scenario.get("title", ""))):
        findings.append(Finding(path, "scenario title should use sentence-style connector capitalization"))
    for mode in ("lab", "exam"):
        block = scenario.get("content", {}).get(mode)
        if not isinstance(block, dict):
            continue
        for title in block.get("task_titles", []):
            if re.search(r"\b(And|With|Of|To|From|For|On|In)\b", str(title)):
                findings.append(Finding(path, f"{mode} task title '{title}' should use sentence-style connector capitalization"))
                break


def audit_rhcsa10_exam_strictness(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa10" not in scenario_tracks(scenario) or "exam" not in scenario.get("content", {}):
        return

    exam = scenario["content"]["exam"]
    for index, (task, check) in enumerate(zip(exam.get("tasks", []), exam.get("checks", [])), start=1):
        task_text = str(task)
        check_text = str(check)
        task_lower = task_text.lower()
        check_lower = check_text.lower()
        label = f"exam task {index}"

        if "baseos" in task_lower and "appstream" in task_lower and "repo" in task_lower:
            missing = [token for token in ("baseurl", "enabled", "gpgcheck") if token not in check_lower]
            if missing:
                findings.append(Finding(path, f"{label} repository check is missing {', '.join(missing)} validation"))
            if re.search(r"\bon server\b|\(server\)", task_text, re.I) and not check_text.lstrip().startswith("ssh server "):
                findings.append(Finding(path, f"{label} repository check must run on server"))

        if "httpd_can_network_connect" in task_text:
            if "getsebool" not in check_lower or "semanage boolean -l -c" not in check_lower:
                findings.append(Finding(path, f"{label} SELinux boolean check must validate runtime and persistent state"))

        is_lvm_mount = (
            re.search(r"\bvg[a-h]10\b", task_lower)
            and re.search(r"\bdata[a-h]\b", task_lower)
            and "mount" in task_lower
        )
        is_nfs_direct_mount = "mount server:/exports/direct" in task_lower and "persist" in task_lower
        if (is_lvm_mount or is_nfs_direct_mount) and "/etc/fstab" not in check_lower:
            findings.append(Finding(path, f"{label} persistent mount check must validate /etc/fstab"))

        if "flatpak" in task_lower and "org.rhcsa.tools" in task_lower:
            if "install" in task_lower and "remove" in task_lower:
                findings.append(Finding(path, f"{label} Flatpak install/remove wording is not provable from final state"))
            if "leave it installed" in task_lower and "flatpak list" not in check_lower:
                findings.append(Finding(path, f"{label} Flatpak installed final state is not checked"))
            if "not installed" in task_lower and "! flatpak list" not in check_lower:
                findings.append(Finding(path, f"{label} Flatpak absent final state is not checked"))


def audit_rhcsa10_at_job_checks(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa10" not in scenario_tracks(scenario):
        return

    content = scenario.get("content", {})
    for mode in ("lab", "exam"):
        block = content.get(mode)
        if not isinstance(block, dict):
            continue
        for index, (task, check) in enumerate(zip(block.get("tasks", []), block.get("checks", [])), start=1):
            task_text = str(task)
            if not re.search(r"\bat job\b|\bqueued at\b|\bschedule\b[\s\S]{0,80}\bat\b", task_text, re.I):
                continue
            label = f"{mode} task {index}"
            if re.search(r"\b(two|[0-9]+)\s+(minute|hour)s?\b", task_text, re.I):
                findings.append(Finding(path, f"{label} uses timing wording that final-state checks cannot prove"))
            check_text = str(check)
            if "at -c" not in check_text or "expected_command" not in check_text:
                findings.append(Finding(path, f"{label} at-job check must validate the queued command content"))


def _explicit_client_target(task_text: str) -> bool:
    return bool(re.search(r"^\s*\(client\)(?=\s|$)|\bon\s+client\b", task_text, re.I))


def _explicit_server_target(task_text: str) -> bool:
    return bool(re.search(r"^\s*\(server\)(?=\s|$)|\bon\s+server\b", task_text, re.I))


def audit_rhcsa10_exam_roles(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa10" not in scenario_tracks(scenario) or "exam" not in scenario.get("content", {}):
        return

    exam = scenario["content"]["exam"]
    for index, task in enumerate(exam.get("tasks", []), start=1):
        task_text = str(task)
        task_lower = task_text.lower()
        label = f"exam task {index}"
        if re.search(r"\bhostname\b[^.]*\bclient[a-h]\.exam10\.lab\b", task_lower) and not _explicit_client_target(task_text):
            findings.append(Finding(path, f"{label} client hostname task must be explicitly targeted to client"))
        if "server:/exports/" in task_lower and not _explicit_client_target(task_text):
            findings.append(Finding(path, f"{label} NFS client mount task must be explicitly targeted to client"))
        if re.search(r"\bhostname\b[^.]*\bserver[a-h]\.exam10\.lab\b", task_lower) and not _explicit_server_target(task_text):
            findings.append(Finding(path, f"{label} server hostname task must be explicitly targeted to server"))


def audit_rhcsa10_exam_target_balance(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa10" not in scenario_tracks(scenario) or "exam" not in scenario.get("content", {}):
        return

    exam = scenario["content"]["exam"]
    tasks = exam.get("tasks", [])
    task_targets = exam.get("task_targets")
    if not isinstance(task_targets, list):
        findings.append(Finding(path, "RHCSA10 exam must include task_targets metadata"))
        return
    if len(task_targets) != len(tasks):
        findings.append(Finding(path, "RHCSA10 exam task_targets length must match tasks"))
        return

    invalid_targets = sorted({str(target) for target in task_targets if str(target) not in {"client", "server", "both"}})
    if invalid_targets:
        findings.append(Finding(path, f"RHCSA10 exam has invalid task target(s): {', '.join(invalid_targets)}"))

    expected_balance = {
        "client_only": task_targets.count("client"),
        "server_only": task_targets.count("server"),
        "client_server": task_targets.count("both"),
    }
    declared_balance = exam.get("target_balance")
    if declared_balance != expected_balance:
        findings.append(Finding(path, f"RHCSA10 exam target_balance must match task_targets ({expected_balance})"))

    task_count = len(tasks)
    if task_count == 22:
        ranges = {"client_only": range(11, 13), "server_only": range(6, 8), "client_server": range(3, 5)}
    elif task_count == 23:
        ranges = {"client_only": range(12, 14), "server_only": range(7, 9), "client_server": range(3, 5)}
    else:
        return

    for key, allowed in ranges.items():
        value = expected_balance[key]
        if value not in allowed:
            findings.append(
                Finding(
                    path,
                    f"RHCSA10 exam target_balance.{key}={value} outside required range "
                    f"{min(allowed)}-{max(allowed)} for {task_count} tasks",
                )
            )


def _exam_target_texts(exam: dict[str, Any], target: str) -> list[str]:
    tasks = [str(task) for task in exam.get("tasks", [])]
    targets = [str(value) for value in exam.get("task_targets", [])]
    return [
        task
        for task, task_target in zip(tasks, targets)
        if task_target == target or task_target == "both"
    ]


def _has_ipv4_task(texts: list[str]) -> bool:
    joined = "\n".join(texts)
    return has_pattern(joined, r"\bipv4\b", r"\bip address\b", r"\beth1\b", r"192\.168\.122\.")


def _has_repo_task(texts: list[str]) -> bool:
    joined = "\n".join(texts)
    return has_pattern(joined, r"\bbaseos\b.*\bappstream\b", r"\brpm repositories\b", r"\brepository definitions\b")


def audit_exam_required_coverage(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "exam" not in scenario.get("content", {}):
        return
    tracks = scenario_tracks(scenario)
    if not ({"rhcsa9", "rhcsa10"} & set(tracks)):
        return

    exam = scenario["content"]["exam"]
    tasks = [str(task) for task in exam.get("tasks", [])]
    targets = [str(value) for value in exam.get("task_targets", [])]
    if len(tasks) not in {22, 23}:
        findings.append(Finding(path, f"exam should have 22 or 23 tasks, found {len(tasks)}"))
    if len(tasks) != len(targets):
        findings.append(Finding(path, "exam task_targets length must match tasks"))
        return

    text = "\n".join(tasks)
    if not bool(scenario.get("flags", {}).get("password_recovery")) or not has_pattern(text, r"recover root access", r"root password recovery"):
        findings.append(Finding(path, "exam must include root password recovery"))

    client_tasks = _exam_target_texts(exam, "client")
    server_tasks = _exam_target_texts(exam, "server")
    if not (_has_ipv4_task(client_tasks) and _has_ipv4_task(server_tasks)):
        findings.append(Finding(path, "exam must include IPv4 networking tasks on client and server"))
    if not (_has_repo_task(client_tasks) and _has_repo_task(server_tasks)):
        findings.append(Finding(path, "exam must include RPM repository tasks on client and server"))

    checks = [str(check) for check in exam.get("checks", [])]
    check_targets = [str(value) for value in exam.get("check_targets", [])]
    for index, (task, target) in enumerate(zip(tasks, targets)):
        task_lower = task.lower()
        if not (
            target == "both"
            and "create user" in task_lower
            and "same uid" in task_lower
            and "client" in task_lower
            and "server" in task_lower
        ):
            continue
        check = checks[index] if index < len(checks) else ""
        check_target = check_targets[index] if index < len(check_targets) else ""
        if check_target != "both" or "ssh" not in check.lower() or "id -u" not in check.lower():
            findings.append(Finding(path, f"exam task {index + 1} creates same-UID user on both hosts but does not verify both hosts"))


def audit_check_target_consistency(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    content = scenario.get("content", {})
    mode = "lab" if "lab" in content else "exam" if "exam" in content else ""
    if not mode:
        return
    block = content[mode]
    checks = [str(check) for check in block.get("checks", [])]
    check_targets = [str(target) for target in block.get("check_targets", [])]
    for index, check in enumerate(checks):
        target = check_targets[index] if index < len(check_targets) else ""
        check_lower = check.lower().strip()
        if (check_lower.startswith("# server") or re.match(r"^ssh\s+\S*server\S*\b", check_lower)) and target not in {"server", "both"}:
            findings.append(Finding(path, f"{mode} check {index + 1} runs on server but check_targets marks {target or 'missing'}"))
        if target == "server" and not (check_lower.startswith("# server") or re.match(r"^ssh\s+\S*server\S*\b", check_lower)):
            findings.append(Finding(path, f"{mode} check {index + 1} is marked server but does not run on server"))


def audit_rhcsa9_exam_check_granularity(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa9" not in scenario_tracks(scenario) or "exam" not in scenario.get("content", {}):
        return

    exam = scenario["content"]["exam"]
    tasks = exam.get("tasks", [])
    checks = exam.get("checks", [])
    task_targets = exam.get("task_targets", [])
    check_targets = exam.get("check_targets", [])
    if len(checks) != len(tasks):
        findings.append(Finding(path, f"RHCSA9 exam checks must match task count ({len(checks)} checks for {len(tasks)} tasks)"))
    if "server" in task_targets and not ({str(target) for target in check_targets} & {"server", "both"}):
        findings.append(Finding(path, "RHCSA9 exam has server tasks but no server-targeted checks"))


def audit_rhcsa9_exam_target_balance(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa9" not in scenario_tracks(scenario) or "exam" not in scenario.get("content", {}):
        return

    exam = scenario["content"]["exam"]
    tasks = exam.get("tasks", [])
    targets = [str(target) for target in exam.get("task_targets", [])]
    if len(tasks) not in {22, 23}:
        findings.append(Finding(path, f"RHCSA9 exam should have 22 or 23 tasks, found {len(tasks)}"))
    if len(targets) != len(tasks):
        findings.append(Finding(path, "RHCSA9 exam task_targets must match task count"))
        return

    expected_balance = {
        "client_only": targets.count("client"),
        "server_only": targets.count("server"),
        "client_server": targets.count("both"),
    }
    if exam.get("target_balance") != expected_balance:
        findings.append(Finding(path, f"RHCSA9 exam target_balance must match task_targets ({expected_balance})"))

    ranges = {
        22: {"client_only": (11, 12), "server_only": (6, 7), "client_server": (3, 4)},
        23: {"client_only": (12, 13), "server_only": (7, 8), "client_server": (3, 4)},
    }
    for key, value in expected_balance.items():
        low, high = ranges[len(tasks)][key]
        if not (low <= value <= high):
            findings.append(Finding(path, f"RHCSA9 exam target_balance.{key}={value} outside required range {low}-{high}"))

    text = authored_text(scenario)
    if not has_pattern(text, r"recover root access"):
        findings.append(Finding(path, "RHCSA9 exam must include root recovery"))
    if not (has_pattern(text, r"on client.*ipv4", r"client.*ip address") and has_pattern(text, r"on server.*ipv4", r"server.*ip address")):
        findings.append(Finding(path, "RHCSA9 exam must include IPv4 networking on client and server"))
    if not (has_pattern(text, r"on client.*baseos.*appstream", r"client.*rpm repositories") and has_pattern(text, r"on server.*baseos.*appstream", r"server.*rpm repositories")):
        findings.append(Finding(path, "RHCSA9 exam must include RPM repositories on client and server"))


def target_derived_lab_scope(scenario: dict[str, Any]) -> str:
    lab = scenario["content"]["lab"]
    return scope_from_targets(lab.get("task_targets", []), requires_server=False)


def audit_rhcsa9_lab_scope(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa9" not in scenario_tracks(scenario) or "lab" not in scenario.get("content", {}):
        return
    scope = normalize_scope(scenario.get("scope"), default="")
    actual_scope = target_derived_lab_scope(scenario)
    if scope != actual_scope:
        findings.append(Finding(path, f"RHCSA9 lab scope should be {actual_scope}, not {scope}"))
    requires_server = bool(scenario.get("flags", {}).get("requires_server", False))
    if actual_scope == "client" and requires_server:
        findings.append(Finding(path, "RHCSA9 client-only lab must not set requires_server=true"))
    if actual_scope != "client" and not requires_server:
        findings.append(Finding(path, f"RHCSA9 {actual_scope} lab must set requires_server=true"))


def audit_rhcsa10_lab_scope(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa10" not in scenario_tracks(scenario) or "lab" not in scenario.get("content", {}):
        return
    scope = normalize_scope(scenario.get("scope"), default="")
    if scope not in {"client", "server", "client-server"}:
        findings.append(Finding(path, "RHCSA10 lab must include scope as client, server, or client-server"))
        return
    actual_scope = target_derived_lab_scope(scenario)
    if scope != actual_scope:
        findings.append(Finding(path, f"RHCSA10 lab scope should be {actual_scope}, not {scope}"))
    requires_server = bool(scenario.get("flags", {}).get("requires_server", False))
    if actual_scope == "client" and requires_server:
        findings.append(Finding(path, "RHCSA10 client-only lab must not set requires_server=true"))
    if actual_scope != "client" and not requires_server:
        findings.append(Finding(path, f"RHCSA10 lab scope {scope} must require server"))


def audit_rhcsa10_lab_script_targets(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa10" not in scenario_tracks(scenario) or "lab" not in scenario.get("content", {}):
        return
    vm_scripts = scenario.get("vm_scripts")
    if not isinstance(vm_scripts, dict) or not vm_scripts:
        return
    scope = normalize_scope(scenario.get("scope"), default="")
    script_targets = {str(target) for target in vm_scripts}
    if scope == "server" and "server" not in script_targets:
        findings.append(Finding(path, "RHCSA10 server lab vm_scripts must include server"))
    if scope == "client" and "client" not in script_targets:
        findings.append(Finding(path, "RHCSA10 client lab vm_scripts must include client"))


def audit_rhcsa10_timer_calendar(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa10" not in scenario_tracks(scenario):
        return

    content = scenario.get("content", {})
    for mode in ("lab", "exam"):
        block = content.get(mode)
        if not isinstance(block, dict):
            continue
        generated_text = "\n".join(flatten_strings([
            block.get("checks", []),
            block.get("solution_commands", []),
        ]))
        if re.search(r"OnCalendar=\*:(?:\*/|/)\d+", generated_text):
            findings.append(Finding(path, f"{mode} timer uses invalid OnCalendar form; use *:0/N"))


def audit_rhcsa10_swap_persistence(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    if "rhcsa10" not in scenario_tracks(scenario):
        return

    content = scenario.get("content", {})
    for mode in ("lab", "exam"):
        block = content.get(mode)
        if not isinstance(block, dict):
            continue
        for index, (task, check) in enumerate(zip(block.get("tasks", []), block.get("checks", [])), start=1):
            task_text = str(task).lower()
            check_text = str(check).lower()
            if "swap" not in task_text or "persist" not in task_text:
                continue
            label = f"{mode} task {index}"
            if "/etc/fstab" not in check_text:
                findings.append(Finding(path, f"{label} swap persistence check must validate /etc/fstab"))
            if "uuid" not in check_text and "/dev/disk/by-uuid" not in check_text:
                findings.append(Finding(path, f"{label} swap persistence check must accept UUID-based fstab entries"))


def audit_persistent_journald(path: Path, scenario: dict[str, Any], findings: list[Finding]) -> None:
    content = scenario.get("content", {})
    for mode in ("lab", "exam"):
        block = content.get(mode)
        if not isinstance(block, dict):
            continue
        tasks_text = "\n".join(flatten_strings(block.get("tasks", [])))
        if not re.search(r"\bpersistent\b[\s\S]{0,80}\bjournal|\bjournal[\s\S]{0,80}\bpersistent\b", tasks_text, re.I):
            continue
        checks_text = "\n".join(flatten_strings(block.get("checks", [])))
        label = f"{mode} persistent journald"
        if "/var/log/journal" not in checks_text:
            findings.append(Finding(path, f"{label} check must validate /var/log/journal"))
        if "Storage" not in checks_text or "Journal" not in checks_text:
            findings.append(Finding(path, f"{label} check must validate Storage=persistent inside a [Journal] section"))
        if re.search(r"grep\b[^\n]*Storage=persistent[^\n]*/etc/systemd/journald\.conf", checks_text):
            findings.append(Finding(path, f"{label} check uses a bare Storage=persistent grep instead of [Journal] parsing"))


def scenario_tracks(scenario: dict[str, Any]) -> list[str]:
    tracks = scenario.get("tracks") or ["rhcsa9"]
    if not isinstance(tracks, list):
        return ["rhcsa9"]
    normalized = []
    for track in tracks:
        value = str(track).strip().lower().replace("-", "").replace("_", "")
        if value in {"rhcsa9", "rhel9", "9", "ex2009"}:
            normalized.append("rhcsa9")
        elif value in {"rhcsa10", "rhel10", "10", "ex20010"}:
            normalized.append("rhcsa10")
    return sorted(set(normalized)) or ["rhcsa9"]


def identity_signature(scenario: dict[str, Any]) -> tuple[str, ...]:
    text = authored_text(scenario)
    signals: list[str] = []
    if has_pattern(text, r"\bgroup\b", r"\buseradd\b", r"users and group"):
        signals.append("group-user")
    if has_pattern(text, r"sudo", r"sudoers"):
        signals.append("sudo")
    if has_pattern(text, r"setgid", r"default acl", r"sticky", r"\+t"):
        signals.append("perm-block")
    if has_pattern(text, r"pwquality", r"password aging", r"chage", r"useradd -d", r"useradd -m", r"useradd -d"):
        signals.append("policy-block")
    if has_pattern(text, r"ssh key", r"\bscp\b", r"\brsync\b"):
        signals.append("ssh-block")
    return tuple(signals)


def normalized_exam_terms(scenario: dict[str, Any]) -> set[str]:
    exam = scenario.get("content", {}).get("exam", {})
    if not isinstance(exam, dict):
        return set()

    text = "\n".join(flatten_strings(exam.get("tasks", [])))
    text = text.lower()
    text = re.sub(r"`[^`]+`", " ", text)
    text = re.sub(r"\b\d+(?:\.\d+){1,3}(?:/\d+)?\b", " ipaddr ", text)
    text = re.sub(r"\b\d+[kmgt]?i?b?\b", " sizevalue ", text)
    text = re.sub(r"/[\w./:-]+", " pathvalue ", text)
    text = re.sub(r"\b[a-z]+[a-h]?(?:9|10)\b", " namevalue ", text)
    text = re.sub(r"[^a-z0-9]+", " ", text)

    terms = set()
    for word in text.split():
        if len(word) <= 2 or word in SIMILARITY_STOP_WORDS:
            continue
        terms.add(word)
    return terms


def audit_exam_similarity(exams: list[tuple[Path, dict[str, Any]]]) -> list[tuple[str, str, str, float]]:
    by_track: dict[str, list[tuple[Path, dict[str, Any], set[str]]]] = {"rhcsa9": [], "rhcsa10": []}
    for path, scenario in exams:
        terms = normalized_exam_terms(scenario)
        for track in scenario_tracks(scenario):
            if track in by_track:
                by_track[track].append((path, scenario, terms))

    similarities: list[tuple[str, str, str, float]] = []
    for track, track_exams in by_track.items():
        for left_index, (left_path, left, left_terms) in enumerate(track_exams):
            for right_path, right, right_terms in track_exams[left_index + 1 :]:
                if not left_terms or not right_terms:
                    continue
                union = left_terms | right_terms
                score = len(left_terms & right_terms) / len(union)
                similarities.append((track, str(left.get("id", left_path.parent.name)), str(right.get("id", right_path.parent.name)), score))
    return sorted(similarities, key=lambda row: row[3], reverse=True)


def main() -> int:
    findings: list[Finding] = []
    labs: list[tuple[Path, dict[str, Any]]] = []
    exams: list[tuple[Path, dict[str, Any]]] = []
    seen_ids: dict[str, Path] = {}

    for path in sorted(SCENARIOS_DIR.glob("labs/*/*/scenario.json")):
        scenario = load_json(path)
        labs.append((path, scenario))
        audit_identity(path, scenario, seen_ids, findings)
        task_lengths_ok(path, scenario, findings)
        audit_target_metadata(path, scenario, findings)
        audit_wording_style(path, scenario, findings)
        audit_solution_style(path, scenario, findings)
        audit_rhcsa9_lab_scope(path, scenario, findings)
        audit_rhcsa10_lab_scope(path, scenario, findings)
        audit_rhcsa10_lab_script_targets(path, scenario, findings)
        audit_rhcsa10_timer_calendar(path, scenario, findings)
        audit_rhcsa10_swap_persistence(path, scenario, findings)
        audit_persistent_journald(path, scenario, findings)
        audit_rhcsa10_at_job_checks(path, scenario, findings)

    for path in sorted(SCENARIOS_DIR.glob("exams/*/*/scenario.json")):
        scenario = load_json(path)
        exams.append((path, scenario))
        audit_identity(path, scenario, seen_ids, findings)
        task_lengths_ok(path, scenario, findings)
        audit_target_metadata(path, scenario, findings)
        audit_wording_style(path, scenario, findings)
        audit_solution_style(path, scenario, findings)
        audit_check_target_consistency(path, scenario, findings)
        audit_rhcsa10_exam_roles(path, scenario, findings)
        audit_rhcsa10_exam_target_balance(path, scenario, findings)
        audit_rhcsa9_exam_check_granularity(path, scenario, findings)
        audit_rhcsa9_exam_target_balance(path, scenario, findings)
        audit_exam_required_coverage(path, scenario, findings)
        audit_rhcsa10_timer_calendar(path, scenario, findings)
        audit_rhcsa10_swap_persistence(path, scenario, findings)
        audit_persistent_journald(path, scenario, findings)
        audit_rhcsa10_exam_strictness(path, scenario, findings)
        audit_rhcsa10_at_job_checks(path, scenario, findings)

    server_labs = [scenario["id"] for _, scenario in labs if scenario["flags"]["requires_server"]]
    if len(server_labs) < 12:
        findings.append(Finding(SCENARIOS_DIR / "labs", f"expected at least 12 labs requiring server, found {len(server_labs)}"))
    rhcsa9_lab_scopes = {"client": 0, "server": 0, "client-server": 0}
    for path, scenario in labs:
        if "rhcsa9" not in scenario_tracks(scenario):
            continue
        actual_scope = target_derived_lab_scope(scenario)
        if actual_scope in rhcsa9_lab_scopes:
            rhcsa9_lab_scopes[actual_scope] += 1
    expected_rhcsa9_lab_scopes = {"client": 22, "server": 14, "client-server": 12}
    if rhcsa9_lab_scopes != expected_rhcsa9_lab_scopes:
        findings.append(
            Finding(
                SCENARIOS_DIR / "labs" / "rhcsa9",
                f"expected RHCSA9 lab target scopes {expected_rhcsa9_lab_scopes}, found {rhcsa9_lab_scopes}",
            )
        )
    rhcsa10_lab_scopes = {"client": 0, "server": 0, "client-server": 0}
    for path, scenario in labs:
        if "rhcsa10" not in scenario_tracks(scenario):
            continue
        actual_scope = target_derived_lab_scope(scenario)
        if actual_scope in rhcsa10_lab_scopes:
            rhcsa10_lab_scopes[actual_scope] += 1
    expected_rhcsa10_lab_scopes = {"client": 22, "server": 14, "client-server": 12}
    if rhcsa10_lab_scopes != expected_rhcsa10_lab_scopes:
        findings.append(
            Finding(
                SCENARIOS_DIR / "labs" / "rhcsa10",
                f"expected RHCSA10 lab target scopes {expected_rhcsa10_lab_scopes}, found {rhcsa10_lab_scopes}",
            )
        )

    exam_counts = {"rhcsa9": 0, "rhcsa10": 0}
    for _path, scenario in exams:
        for track in scenario_tracks(scenario):
            if track in exam_counts:
                exam_counts[track] += 1
    for track, count in exam_counts.items():
        if count != 8:
            findings.append(Finding(SCENARIOS_DIR / "exams" / track, f"expected 8 {track.upper()} exams, found {count}"))

    exam_similarity_rows = audit_exam_similarity(exams)

    recurring_limits = {
        "root recovery": ({"rhcsa9": 8, "rhcsa10": 8}, lambda text: has_pattern(text, r"root recovery", r"recover root access", r"password recovery")),
        "repo on both hosts": (
            {"rhcsa9": 8, "rhcsa10": 8},
            lambda text: (
                has_pattern(text, r"repositories on both systems")
                or (has_pattern(text, r"client repositor") and has_pattern(text, r"server repositor"))
                or has_pattern(text, r"same repository file on server")
                or has_pattern(text, r"client and server.*baseos.*appstream")
            ),
        ),
        "apache custom port/docroot": (
            {"rhcsa9": 8, "rhcsa10": 8},
            lambda text: has_pattern(text, r"apache", r"httpd")
            and has_pattern(text, r"docroot", r"document root", r"listen", r"http_port_t", r"httpd[^\n]{0,80}\bport\b", r"\bport\b[^\n]{0,80}httpd"),
        ),
        "chrony": ({"rhcsa9": 8, "rhcsa10": 8}, lambda text: has_pattern(text, r"chrony")),
        "autofs/nfs": ({"rhcsa9": 8, "rhcsa10": 8}, lambda text: has_pattern(text, r"autofs", r"\bnfs\b")),
        "rootless container": ({"rhcsa9": 8, "rhcsa10": 0}, lambda text: has_pattern(text, r"rootless container", r"podman run", r"loginctl enable-linger")),
    }

    recurring_counts: dict[str, dict[str, int]] = {
        "rhcsa9": {key: 0 for key in recurring_limits},
        "rhcsa10": {key: 0 for key in recurring_limits},
    }
    meaningful_server_exams = 0
    identity_variant_exams = 0
    perms_variant_exams = 0
    identity_signatures: dict[str, dict[tuple[str, ...], list[str]]] = {
        "rhcsa9": {},
        "rhcsa10": {},
    }

    for path, scenario in exams:
        text = scenario_text(scenario)
        tracks = scenario_tracks(scenario)
        for track in tracks:
            for key, (limit, detector) in recurring_limits.items():
                if detector(text):
                    recurring_counts.setdefault(track, {key: 0 for key in recurring_limits})[key] += 1

        if scenario["flags"]["requires_server"] and has_pattern(
            text,
            r"server.*chrony",
            r"server.*httpd",
            r"server.*firewalld",
            r"server.*journal",
            r"server.*target",
            r"server.*sudo",
            r"server.*ssh",
            r"server.*package",
        ):
            meaningful_server_exams += 1

        if has_pattern(
            text,
            r"\b-M\b",
            r"\b-u\b",
            r"useradd -D",
            r"\bchage\b",
            r"password aging",
            r"pwquality",
            r"ssh key",
            r"\bscp\b",
            r"\brsync\b",
        ):
            identity_variant_exams += 1

        if has_pattern(
            text,
            r"sticky",
            r"default acl",
            r"restorecon",
            r"selinux boolean",
            r"document root",
            r"docroot",
            r"rich rule",
        ):
            perms_variant_exams += 1

        signature = identity_signature(scenario)
        for track in tracks:
            identity_signatures.setdefault(track, {}).setdefault(signature, []).append(scenario["id"])

    for track, counts in recurring_counts.items():
        for key, count in counts.items():
            limit_spec = recurring_limits[key][0]
            limit = limit_spec.get(track, 0) if isinstance(limit_spec, dict) else limit_spec
            if count > limit:
                findings.append(Finding(SCENARIOS_DIR / "exams", f"'{key}' appears in {count} {track} exams (limit {limit})"))

    if meaningful_server_exams < 4:
        findings.append(Finding(SCENARIOS_DIR / "exams", f"expected at least 4 exams with meaningful server work, found {meaningful_server_exams}"))
    if identity_variant_exams < 4:
        findings.append(Finding(SCENARIOS_DIR / "exams", f"expected at least 4 exams with non-default identity/security variants, found {identity_variant_exams}"))
    if perms_variant_exams < 4:
        findings.append(Finding(SCENARIOS_DIR / "exams", f"expected at least 4 exams with non-default permissions/SELinux variants, found {perms_variant_exams}"))

    if findings:
        for finding in findings:
            rel = finding.path.relative_to(ROOT) if finding.path.is_relative_to(ROOT) else finding.path
            print(f"[fail] {rel}: {finding.message}")
        return 1

    print("Scenario audit passed.")
    print(f"Server-required labs: {len(server_labs)}")
    print(f"Meaningful server exams: {meaningful_server_exams}")
    print(f"Identity/security variant exams: {identity_variant_exams}")
    print(f"Permissions/SELinux variant exams: {perms_variant_exams}")
    if exam_similarity_rows:
        print("Highest exam similarity:")
        for track in ("rhcsa9", "rhcsa10"):
            track_rows = [row for row in exam_similarity_rows if row[0] == track]
            for _, left_id, right_id, score in track_rows[:EXAM_SIMILARITY_REPORT_LIMIT]:
                print(f"- {track}: {left_id} vs {right_id}: {score:.2f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
