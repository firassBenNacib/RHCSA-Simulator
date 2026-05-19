#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SCENARIOS_DIR = ROOT / "scenarios"
DIRECT_SUDOERS_RE = re.compile(r"(?<!\S)/etc/sudoers(?!\.d(?:/|\b))")


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
    if "exam" in content:
        exam = content["exam"]
        tasks = exam["tasks"]
        expected = len(tasks)
        for key in ("task_titles", "task_points", "solution_commands"):
            if len(exam[key]) != expected:
                findings.append(Finding(path, f"exam field '{key}' length does not match tasks"))
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
        audit_solution_style(path, scenario, findings)

    for path in sorted(SCENARIOS_DIR.glob("exams/*/*/scenario.json")):
        scenario = load_json(path)
        exams.append((path, scenario))
        audit_identity(path, scenario, seen_ids, findings)
        task_lengths_ok(path, scenario, findings)
        audit_solution_style(path, scenario, findings)

    server_labs = [scenario["id"] for _, scenario in labs if scenario["flags"]["requires_server"]]
    if len(server_labs) < 12:
        findings.append(Finding(SCENARIOS_DIR / "labs", f"expected at least 12 labs requiring server, found {len(server_labs)}"))

    recurring_limits = {
        "root recovery": (3, lambda text: has_pattern(text, r"root recovery", r"password recovery")),
        "repo on both hosts": (
            4,
            lambda text: (
                has_pattern(text, r"repositories on both systems")
                or (has_pattern(text, r"client repositor") and has_pattern(text, r"server repositor"))
                or has_pattern(text, r"same repository file on server")
            ),
        ),
        "apache custom port/docroot": (
            3,
            lambda text: has_pattern(text, r"apache", r"httpd")
            and has_pattern(text, r"docroot", r"document root", r"listen", r"http_port_t", r"httpd[^\n]{0,80}\bport\b", r"\bport\b[^\n]{0,80}httpd"),
        ),
        "chrony": (3, lambda text: has_pattern(text, r"chrony")),
        "autofs/nfs": (4, lambda text: has_pattern(text, r"autofs", r"\bnfs\b")),
        "rootless container autostart": (3, lambda text: has_pattern(text, r"container autostart", r"systemctl --user", r"loginctl enable-linger")),
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
            limit = recurring_limits[key][0]
            if count > limit:
                findings.append(Finding(SCENARIOS_DIR / "exams", f"'{key}' appears in {count} {track} exams (limit {limit})"))

    if meaningful_server_exams < 4:
        findings.append(Finding(SCENARIOS_DIR / "exams", f"expected at least 4 exams with meaningful server work, found {meaningful_server_exams}"))
    if identity_variant_exams < 4:
        findings.append(Finding(SCENARIOS_DIR / "exams", f"expected at least 4 exams with non-default identity/security variants, found {identity_variant_exams}"))
    if perms_variant_exams < 4:
        findings.append(Finding(SCENARIOS_DIR / "exams", f"expected at least 4 exams with non-default permissions/SELinux variants, found {perms_variant_exams}"))

    for track, signatures in sorted(identity_signatures.items()):
        for signature, exam_ids in sorted(signatures.items()):
            if len(exam_ids) > 1 and set(signature) >= {"group-user", "sudo", "perm-block"}:
                findings.append(Finding(SCENARIOS_DIR / "exams", f"repeated identity/sudo/permissions block across {track} exams: {', '.join(exam_ids)}"))

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
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
