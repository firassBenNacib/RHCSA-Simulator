from __future__ import annotations

import re
from typing import Any, Iterable


VALID_TARGETS = {"client", "server", "both"}
VALID_SCOPES = {"client", "server", "client-server"}


def normalize_target(value: Any, default: str = "client") -> str:
    target = str(value or "").strip().lower().replace("_", "-")
    if target in {"client", "server", "both"}:
        return target
    if target in {"client-server", "client/server", "server-client", "server/client"}:
        return "both"
    return default


def normalize_scope(value: Any, default: str = "client") -> str:
    scope = str(value or "").strip().lower().replace("_", "-")
    if scope in VALID_SCOPES:
        return scope
    if scope in {"both", "client/server", "server-client", "server/client"}:
        return "client-server"
    return default


def scope_from_targets(targets: Iterable[Any] | None, requires_server: bool = False) -> str:
    normalized = [normalize_target(target) for target in (targets or [])]
    has_client = any(target in {"client", "both"} for target in normalized)
    has_server = any(target in {"server", "both"} for target in normalized)
    if has_client and has_server:
        return "client-server"
    if has_server:
        return "server"
    if requires_server:
        return "client-server"
    return "client"


def target_system_label(target: str) -> str:
    target = normalize_target(target)
    if target == "both":
        return "client + server"
    return target


def _comment_markers(command_group: Iterable[Any] | None) -> list[str]:
    return [
        str(command).strip().lower()
        for command in (command_group or [])
        if str(command).strip().startswith("#")
    ]


def _has_server_marker(command_group: Iterable[Any] | None) -> bool:
    markers = _comment_markers(command_group)
    return any(marker.startswith("# on server") or "run on server" in marker for marker in markers)


def _has_client_marker(command_group: Iterable[Any] | None) -> bool:
    markers = _comment_markers(command_group)
    return any(marker.startswith("# on client") or "run on client" in marker for marker in markers)


def infer_task_target(task: Any, command_group: Iterable[Any] | None = None, default: str = "client") -> str:
    text = str(task or "")
    lowered = text.lower()
    explicit_server = bool(re.search(r"^\s*\(server\)|^\s*on\s+server\b|\bon\s+server\b", lowered))
    explicit_client = bool(re.search(r"^\s*\(client\)|^\s*on\s+client\b|\bon\s+client\b", lowered))
    has_server_marker = _has_server_marker(command_group)
    has_client_marker = _has_client_marker(command_group)
    integrated = bool(
        re.search(r"\bon client and server\b|\bon server and client\b|both client and server", lowered)
        or "server:/" in lowered
        or re.search(r"\bcopy\b.*\bserver:", lowered)
        or re.search(r"\bssh\b.*\bserver\b", lowered)
    )
    if integrated or (explicit_client and explicit_server) or (has_server_marker and (has_client_marker or explicit_client)):
        return "both"
    if explicit_server or has_server_marker:
        return "server"
    if explicit_client:
        return "client"
    return normalize_target(default)


def infer_solution_target(command_group: Iterable[Any] | None, task_target: str = "client") -> str:
    commands = [str(command) for command in (command_group or [])]
    has_server_marker = _has_server_marker(commands)
    has_client_marker = _has_client_marker(commands)
    has_local_commands = any(command.strip() and not command.strip().startswith("#") for command in commands)
    if has_server_marker and (has_client_marker or normalize_target(task_target) == "both"):
        return "both"
    if has_server_marker and not has_client_marker:
        return "server"
    if any(re.search(r"^\s*ssh\s+\S*server\S*\b", command) for command in commands):
        return "client"
    if has_local_commands:
        return normalize_target(task_target)
    return normalize_target(task_target)


def infer_check_target(command: Any, requires_server: bool = False) -> str:
    text = str(command or "").strip()
    lowered = text.lower()
    if re.match(r"^\s*#\s*server\b", lowered) or re.match(r"^\s*ssh\s+\S*server\S*\b", lowered):
        if re.search(r"&&\s*(?!ssh\s+\S*server\S*)[^&]+server:/", lowered):
            return "both"
        return "server"
    if not requires_server:
        return "client"
    if "server:/" in lowered or re.search(r"\bssh\s+\S*server\S*\b", lowered):
        return "both"
    return "client"


def normalize_title_capitalization(value: Any) -> str:
    text = str(value or "").strip()
    for word in ("And", "With", "Of", "To", "From", "For", "On", "In"):
        text = re.sub(rf"\b{word}\b", word.lower(), text)
    text = re.sub(r"\bL[Vv]\b", "LV", text)
    text = re.sub(r"\bRpm\b", "RPM", text)
    text = re.sub(r"\bIpv4\b", "IPv4", text)
    text = re.sub(r"\bIpv6\b", "IPv6", text)
    text = re.sub(r"\bSsh\b", "SSH", text)
    text = re.sub(r"\bNfs\b", "NFS", text)
    text = re.sub(r"\bAcl\b", "ACL", text)
    return text


def normalize_authored_wording(value: Any) -> str:
    text = str(value or "")
    text = re.sub(r"\bRHCSA style\b", "RHCSA practice", text, flags=re.I)
    text = re.sub(r"(?i)\bDNS SERVER\s*:", "DNS:", text)
    text = re.sub(r"(?i)\bDNS Server\s*:", "DNS:", text)
    return text


def prefix_task_target(task: Any, target: str) -> str:
    text = normalize_authored_wording(task).strip()
    target = normalize_target(target)
    text = re.sub(r"^\s*\((client|server)\)\s*", "", text, flags=re.I)
    if re.match(r"^\s*on\s+(client|server)\b", text, re.I):
        return text
    prefix_target = "server" if target == "server" else "client"
    if not text:
        return f"On {prefix_target}, complete the requested configuration."
    return f"On {prefix_target}, {text[0].lower()}{text[1:]}"
