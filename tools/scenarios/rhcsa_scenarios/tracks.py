from __future__ import annotations


def normalize_track(value: str | None) -> str:
    normalized = (value or "").strip().lower().replace("-", "").replace("_", "")
    if normalized in {"", "all"}:
        return "all"
    if normalized in {"9", "rhel9", "rhcsa9", "ex2009"}:
        return "rhcsa9"
    if normalized in {"10", "rhel10", "rhcsa10", "ex20010"}:
        return "rhcsa10"
    raise SystemExit(f"Unsupported track: {value}")


def manifest_tracks(value: object) -> set[str]:
    if not value:
        return {"rhcsa9"}
    if not isinstance(value, list):
        raise SystemExit("Scenario tracks must be a list.")
    return {normalize_track(str(item)) for item in value}

