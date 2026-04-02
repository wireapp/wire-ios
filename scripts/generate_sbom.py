#!/usr/bin/env python3
"""
generate_sbom.py - Generate a complete CycloneDX SBOM for wire-ios.

Combines:
  - SPM dependencies from Package.resolved (via trivy)
  - Binary xcframework targets from local Package.swift files
  - Carthage dependencies from Cartfile.resolved
"""

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
PACKAGE_RESOLVED = ROOT / "wire-ios-mono.xcworkspace/xcshareddata/swiftpm/Package.resolved"
CARTFILE_RESOLVED = ROOT / "Cartfile.resolved"
OUTPUT = ROOT / "bom.json"

EXCLUDE_DIRS = {"DerivedData", "Carthage", ".build"}


def run_trivy():
    print("Running trivy on Package.resolved...")
    result = subprocess.run(
        ["trivy", "fs", "--format", "cyclonedx", "--output", str(OUTPUT), str(PACKAGE_RESOLVED)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"trivy failed:\n{result.stderr}", file=sys.stderr)
        sys.exit(1)
    print("  Done.")


def find_local_package_swifts():
    return [
        p for p in ROOT.rglob("Package.swift")
        if not set(p.parts).intersection(EXCLUDE_DIRS)
    ]


def extract_binary_targets(package_swift: Path):
    content = package_swift.read_text()
    targets = []
    pattern = re.compile(
        r'\.binaryTarget\s*\(\s*'
        r'name:\s*"([^"]+)"\s*,\s*'
        r'url:\s*"([^"]+)"\s*,\s*'
        r'checksum:\s*"([^"]+)"\s*\)',
        re.DOTALL
    )
    for m in pattern.finditer(content):
        name, url, checksum = m.group(1), m.group(2), m.group(3)
        version_match = re.search(r'/releases/download/v?([^/]+)/', url)
        version = version_match.group(1) if version_match else "unknown"
        repo_match = re.search(r'github\.com/([^/]+/[^/]+?)(?:\.git)?/', url)
        repo = repo_match.group(1) if repo_match else None
        targets.append({"name": name, "version": version, "url": url, "checksum": checksum, "repo": repo})
    return targets


def parse_cartfile_resolved():
    components = []
    if not CARTFILE_RESOLVED.exists():
        return components
    pattern = re.compile(r'^github\s+"([^/]+/[^"]+)"\s+"([^"]+)"', re.MULTILINE)
    for m in pattern.finditer(CARTFILE_RESOLVED.read_text()):
        repo, version = m.group(1), m.group(2)
        name = repo.split("/")[-1]
        components.append({
            "type": "library",
            "name": name,
            "version": version,
            "purl": f"pkg:github/{repo}@{version}",
            "externalReferences": [{"type": "vcs", "url": f"https://github.com/{repo}"}],
            "properties": [{"name": "dependency-manager", "value": "carthage"}],
        })
    return components


def build_binary_component(target):
    component = {
        "type": "library",
        "name": target["name"],
        "version": target["version"],
        "externalReferences": [{"type": "distribution", "url": target["url"]}],
        "properties": [
            {"name": "dependency-manager", "value": "spm-binary-target"},
            {"name": "checksum-sha256", "value": target["checksum"]},
        ],
    }
    if target["repo"]:
        component["purl"] = f"pkg:github/{target['repo']}@{target['version']}"
    return component


def merge_into_bom(extra_components):
    with open(OUTPUT) as f:
        bom = json.load(f)

    existing_purls = {c.get("purl") for c in bom.get("components", [])}
    existing_names = {c.get("name") for c in bom.get("components", [])}
    added = 0

    for comp in extra_components:
        purl = comp.get("purl")
        name = comp.get("name")
        if (purl and purl in existing_purls) or name in existing_names:
            print(f"  Skipping {name} (already present)")
            continue
        bom.setdefault("components", []).append(comp)
        print(f"  Added: {name} {comp.get('version', '')}")
        added += 1

    with open(OUTPUT, "w") as f:
        json.dump(bom, f, indent=2)

    return added, len(bom.get("components", []))


def main():
    run_trivy()

    extra = []

    print("\nScanning local Package.swift files for binary targets...")
    for pkg_swift in find_local_package_swifts():
        targets = extract_binary_targets(pkg_swift)
        if targets:
            print(f"  {pkg_swift.relative_to(ROOT)}: {len(targets)} binary target(s)")
            extra.extend(build_binary_component(t) for t in targets)

    print("\nParsing Cartfile.resolved...")
    carthage = parse_cartfile_resolved()
    if carthage:
        print(f"  Found {len(carthage)} Carthage dependency(ies)")
        extra.extend(carthage)
    else:
        print("  Nothing found.")

    print(f"\nMerging {len(extra)} extra component(s) into bom.json...")
    added, total = merge_into_bom(extra)
    print(f"\nDone. Added {added} component(s). Total components in SBOM: {total}")
    print(f"Output: {OUTPUT}")


if __name__ == "__main__":
    main()
