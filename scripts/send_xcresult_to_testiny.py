#!/usr/bin/env python3

"""
Upload XCUITest results to Testiny via REST API.

How it works
- Reads an .xcresult
- Extracts Testiny case IDs from test names using the pattern: _TC_<id>[_<id>...]
  Examples:
    test_Login_TC_1234()            -> TC-1234
    test_Login_TC_1234_1111_2222()  -> TC-1234, TC-1111, TC-2222
- Finds a Testiny test run by title and updates the matching test cases with PASSED/FAILED/SKIPPED

Usage
  python3 send_xcresult_to_testiny.py --xcresult <path>.xcresult --run-name "My Run" [--require-existing-run]

Environment
  TESTINY_API_KEY     Required. Testiny API key.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from typing import List, Dict

TESTINY_BASE_URL = "https://app.testiny.io/api/v1"
TESTINY_API_KEY = os.environ.get("TESTINY_API_KEY")
PROJECT_FIELD: Dict = {"project_id": 7} #IOS

@dataclass
class FlatTest:
    name: str
    status: str
    tc_keys: List[str] = field(default_factory=list)

@dataclass
class PendingResult:
    run_id: int
    test_case_id: int
    status: str


def extract_tc_keys(test_name: str) -> List[str]:
    """
    Extract TC IDs from function name.
    Example:
        test_Login_TC_1234_1111_2222
        -> ["TC-1234", "TC-1111", "TC-2222"]
    """
    m = re.search(r'_TC_(\d+)((?:_\d+)*)', test_name, re.IGNORECASE)
    if not m:
        return []

    keys = [f"TC-{m.group(1)}"]
    if m.group(2):
        keys += [f"TC-{n}" for n in re.findall(r'\d+', m.group(2))]
    return keys


STATUS_MAP = {
    "Success": "PASSED",
    "Failure": "FAILED",
    "Skipped": "SKIPPED",
    "Expected Failure": "FAILED",
    "Error": "FAILED",
    "Passed": "PASSED",
    "Failed": "FAILED",
    "passed": "PASSED",
    "failed": "FAILED",
    "skipped": "SKIPPED",
    "error": "FAILED",
}



def map_status(raw: str) -> str:
    status = STATUS_MAP.get(raw)
    if status is None:
        print(f"[WARN] Unrecognised test status '{raw}', defaulting to NOTRUN")
        return "NOTRUN"
    return status

def execute_xcresulttool(*args: str) -> dict:
    cmd = ["xcrun", "xcresulttool"] + list(args)
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    if r.returncode != 0:
        raise RuntimeError(f"xcresulttool error:\n{r.stderr.strip()}")
    return json.loads(r.stdout)

def collect_test_nodes_new_api(root: dict, tests: list):
    stack = [root]
    while stack:
        node = stack.pop()
        if not isinstance(node, dict):
            continue
        if node.get("nodeType") == "Test Case":
            name = node.get("name", "").rstrip("()")
            result = node.get("result", "unknown")
            tests.append({"name": name, "status": result})
        stack.extend(node.get("children", []))


def parse_xcresult_new_api(path: str) -> List[FlatTest]:
    print("[INFO] Using Xcode 16+ xcresulttool API")
    data = execute_xcresulttool("get", "test-results", "tests", "--path", path)
    raw = []
    for node in data.get("testNodes", []):
        collect_test_nodes_new_api(node, raw)
    return build_flat_test_models(raw)


def collect_test_nodes_legacy(root, tests):
    stack = [root]
    while stack:
        node = stack.pop()
        if isinstance(node, list):
            stack.extend(node)
            continue
        if not isinstance(node, dict):
            continue
        if node.get("_type", {}).get("_name") == "ActionTestMetadata":
            identifier = node.get("identifier", {}).get("_value", "")
            status = node.get("testStatus", {}).get("_value", "")
            if identifier:
                func = identifier.split("/")[-1].rstrip("()")
                tests.append({"name": func, "status": status})
        stack.extend(
            v for k, v in node.items()
            if k not in ("_type", "_value") and isinstance(v, (dict, list))
        )

def parse_xcresult_legacy(path: str) -> List[FlatTest]:
    print("[INFO] Using legacy xcresulttool API")
    top = execute_xcresulttool("get", "--legacy", "--format", "json", "--path", path)

    raw = []
    collect_test_nodes_legacy(top, raw)
    return build_flat_test_models(raw)

def parse_xcresult(path: str) -> List[FlatTest]:
    print(f"[INFO] Parsing XCResult: {path}")

    probe = subprocess.run(
        ["xcrun", "xcresulttool", "get", "test-results", "--help"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=30,
    )

    if probe.returncode == 0:
        try:
            return parse_xcresult_new_api(path)
        except Exception as e:
            print(f"[WARN] New API failed ({e}), falling back to legacy")

    return parse_xcresult_legacy(path)


def parse_junit_xml(path: str) -> List[FlatTest]:
    print(f"[INFO] Parsing JUnit XML: {path}")
    tree = ET.parse(path)
    root = tree.getroot()

    raw = []
    for tc in root.iter("testcase"):
        name = tc.get("name", "").rstrip("()")
        if tc.find("failure") is not None or tc.find("error") is not None:
            status = "Failure"
        elif tc.find("skipped") is not None:
            status = "Skipped"
        else:
            status = "Success"
        raw.append({"name": name, "status": status})

    return build_flat_test_models(raw)


def build_flat_test_models(raw: list) -> List[FlatTest]:
    return [
        FlatTest(
            name=t["name"],
            status=t["status"],
            tc_keys=extract_tc_keys(t["name"])
        )
        for t in raw
    ]


def call_testiny_api(method: str, endpoint: str, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        f"{TESTINY_BASE_URL}{endpoint}",
        data=data,
        headers={"Content-Type": "application/json", "X-Api-Key": TESTINY_API_KEY},
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        raise RuntimeError(
            f"Testiny {method} {endpoint} -> {e.code}: {e.read().decode()}"
        )
    except urllib.error.URLError as e:
        raise RuntimeError(f"Network error calling {endpoint}: {e.reason}")

def append_ci_summary(run_id: int, run_name: str) -> None:
    github_server = os.environ.get("GITHUB_SERVER_URL")
    github_repo = os.environ.get("GITHUB_REPOSITORY")
    github_run_id = os.environ.get("GITHUB_RUN_ID")
    github_run_number = os.environ.get("GITHUB_RUN_NUMBER")

    if not github_server or not github_repo or not github_run_id:
        return

    build_url = f"{github_server}/{github_repo}/actions/runs/{github_run_id}"

    try:
        run = call_testiny_api("GET", f"/testrun/{run_id}")
        description = run.get("description")

        try:
            doc = json.loads(description) if description else {"t": "slate", "v": 1, "c": []}
        except Exception:
            doc = {"t": "slate", "v": 1, "c": []}

        link_label = f"{run_name}"
        if github_run_number:
            link_label += f" #{github_run_number}"
        link_label += ": "

        doc["c"].append({
            "t": "p",
            "children": [
                {"text": link_label},
                {"t": "a", "url": build_url, "children": [{"text": build_url}]},
                {"text": ""}
            ]
        })

        call_testiny_api(
            "PUT",
            f"/testrun/{run_id}?force=true",
            {"description": json.dumps(doc)}
        )

    except Exception as e:
        print(f"[WARN] Could not update Testiny run description: {e}")

# Find an existing run by the provided name
def resolve_run(title: str, require_existing: bool) -> int:
    found = call_testiny_api("POST", "/testrun/find", {"filter": {"title": title, **PROJECT_FIELD}})

    if found.get("data"):
        if len(found["data"]) > 1:
            print(f"[WARN] Multiple runs named '{title}', using the first match")
        run_id = found["data"][0]["id"]
        print(f"[OK] Found existing run '{title}' (ID {run_id})")
        return run_id

    if require_existing:
        raise RuntimeError(f"Run '{title}' not found and --require-existing-run set")

    print(f"[INFO] Creating test run '{title}'")
    run = call_testiny_api("POST", "/testrun", {"title": title, **PROJECT_FIELD})
    return run["id"]


def find_testiny_id(tc_key: str) -> int | None:
    numeric = re.sub(r'^TC-', '', tc_key, flags=re.IGNORECASE)
    if not numeric.isdigit():
        return None
    try:
        tc = call_testiny_api("GET", f"/testcase/{numeric}")
        return tc["id"]
    except Exception:
        return None


def bulk_send(results: List[PendingResult]) -> None:
    payload = [
        {
            "ids": {"testcase_id": r.test_case_id, "testrun_id": r.run_id},
            "mapped": {"result_status": r.status, "assigned_to": "OWNER"},
        }
        for r in results
    ]
    call_testiny_api("POST", "/testrun/mapping/bulk/testcase:testrun?op=add_or_update", payload)


def resolve_test_cases(tests: List[FlatTest], run_id: int):
    results_to_upload = []
    skipped_no_tag = 0
    skipped_missing = 0

    for t in tests:
        if not t.tc_keys:
            skipped_no_tag += 1
            continue

        status = map_status(t.status)

        for key in t.tc_keys:
            tc_id = find_testiny_id(key)
            if tc_id is None:
                print(f"[WARN] {key} not found in Testiny")
                skipped_missing += 1
                continue

            results_to_upload.append(PendingResult(run_id, tc_id, status))

    return results_to_upload, skipped_no_tag, skipped_missing


def parse_args():
    p = argparse.ArgumentParser(description="Send XCUITest results to Testiny.")
    src = p.add_mutually_exclusive_group(required=True)
    src.add_argument("--xcresult")
    src.add_argument("--junit")
    p.add_argument("--run-name", required=True)
    p.add_argument("--require-existing-run", action="store_true")
    return p.parse_args()

def main():
    args = parse_args()

    if not TESTINY_API_KEY:
        sys.exit("TESTINY_API_KEY not set")

    if args.xcresult:
        if not os.path.exists(args.xcresult):
            sys.exit("XCResult not found")
        tests = parse_xcresult(args.xcresult)
    else:
        if not os.path.exists(args.junit):
            sys.exit("JUnit not found")
        tests = parse_junit_xml(args.junit)

    print(f"[INFO] {len(tests)} test(s) loaded")

    run_id = resolve_run(args.run_name, args.require_existing_run)

    pending, skipped_no_tag, skipped_missing = resolve_test_cases(tests, run_id)

    dedup = {}
    for r in pending:
        dedup[f"{r.test_case_id}:{r.run_id}"] = r

    final = list(dedup.values())

    exit_code = 0
    if final:
        print(f"[INFO] Sending {len(final)} result(s)")
        try:
            bulk_send(final)
            print("[OK] Upload successful")
        except Exception as e:
            print(f"[ERROR] Upload failed: {e}", file=sys.stderr)
            exit_code = 1
    else:
        print("[INFO] No results to send")

    append_ci_summary(run_id, args.run_name)
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
