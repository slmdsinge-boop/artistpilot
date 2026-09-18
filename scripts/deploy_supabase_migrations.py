#!/usr/bin/env python3
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

API_BASE = "https://api.supabase.com/v1"


def request(method, url, token, body=None):
    data = None
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
    }
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=190) as response:
            raw = response.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Supabase API returned HTTP {exc.code}: {detail}") from exc


def main():
    token = os.environ.get("SUPABASE_ACCESS_TOKEN")
    project_ref = os.environ.get("SUPABASE_PROJECT_REF")
    if not token or not project_ref:
        print("Missing SUPABASE_ACCESS_TOKEN or SUPABASE_PROJECT_REF", file=sys.stderr)
        return 2

    migrations_dir = Path("supabase/migrations")
    migration_files = sorted(migrations_dir.glob("*.sql"))
    if not migration_files:
        print("No SQL migrations found.")
        return 0

    endpoint = f"{API_BASE}/projects/{project_ref}/database/migrations"
    history = request("GET", endpoint, token)
    applied_names = {
        item.get("name")
        for item in history
        if isinstance(item, dict) and item.get("name")
    }

    for path in migration_files:
        migration_name = path.stem
        if migration_name in applied_names:
            print(f"Skipping already applied migration: {migration_name}")
            continue

        print(f"Applying migration: {migration_name}")
        sql = path.read_text(encoding="utf-8")
        request(
            "POST",
            endpoint,
            token,
            {"query": sql, "name": migration_name},
        )
        print(f"Applied migration: {migration_name}")

    print("All Supabase migrations are up to date.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
