#!/usr/bin/env python3
"""
generate_sbom.py - Generate a complete CycloneDX SBOM for wire-ios.

Combines:
  - SPM dependencies from Package.resolved (via trivy)
  - Binary xcframework targets from local Package.swift files
  - Carthage dependencies from Cartfile.resolved
  - Ruby gems from Gemfile.lock

Enriches all GitHub-hosted components with license information via the GitHub API.
Set GITHUB_TOKEN in the environment to avoid rate limiting.
"""

import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).parent.parent
PACKAGE_RESOLVED = ROOT / "wire-ios-mono.xcworkspace/xcshareddata/swiftpm/Package.resolved"
CARTFILE_RESOLVED = ROOT / "Cartfile.resolved"
GEMFILE_LOCK = ROOT / "Gemfile.lock"
OUTPUT = ROOT / "bom.json"

EXCLUDE_DIRS = {"DerivedData", "Carthage", ".build"}

_license_cache: dict = {}


def run_trivy():
    print("Running trivy on Package.resolved...")
    result = subprocess.run(
        ["trivy", "fs", "--format", "cyclonedx", "--output", str(OUTPUT), str(PACKAGE_RESOLVED)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"trivy failed:\n{result.stderr}", file=sys.stderr)
        sys.exit(1)

    # Trivy adds the scanned file itself as an application component — remove it.
    with open(OUTPUT) as f:
        bom = json.load(f)
    bom["components"] = [
        c for c in bom.get("components", [])
        if c.get("name") != "Package.resolved"
    ]
    with open(OUTPUT, "w") as f:
        json.dump(bom, f, indent=2)
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


def parse_gemfile_lock():
    """Parse root Gemfile.lock and return CycloneDX components for all resolved gems."""
    if not GEMFILE_LOCK.exists():
        return []

    components = []
    in_specs = False
    # Gem spec lines are indented with exactly 4 spaces: "    name (version)"
    gem_pattern = re.compile(r'^    (\S+) \(([^)]+)\)$')

    for line in GEMFILE_LOCK.read_text().splitlines():
        if line.strip() == "specs:":
            in_specs = True
            continue
        # A non-empty line without leading whitespace signals a new top-level section
        if in_specs and line and not line.startswith(" "):
            break
        if in_specs:
            m = gem_pattern.match(line)
            if m:
                name, version = m.group(1), m.group(2)
                components.append({
                    "type": "library",
                    "name": name,
                    "version": version,
                    "purl": f"pkg:gem/{name}@{version}",
                    "externalReferences": [{"type": "website", "url": f"https://rubygems.org/gems/{name}"}],
                    "properties": [{"name": "dependency-manager", "value": "bundler"}],
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
        component["externalReferences"].append({
            "type": "vcs",
            "url": f"https://github.com/{target['repo']}",
        })
    return component


def extract_github_repo(comp: dict):
    """Extract 'owner/repo' from a component's purl or name field, or None."""
    purl = comp.get("purl", "")
    # pkg:swift/github.com/owner/repo@version  (SPM packages from trivy)
    m = re.match(r'pkg:swift/github\.com/([^/@]+/[^@]+)@', purl)
    if m:
        return m.group(1)
    # pkg:github/owner/repo@version  (binary targets, Carthage)
    m = re.match(r'pkg:github/([^@]+)@', purl)
    if m:
        return m.group(1)
    # name: github.com/owner/repo  (trivy fallback)
    name = comp.get("name", "")
    m = re.match(r'github\.com/([^/]+/[^/]+)$', name)
    if m:
        return m.group(1)
    return None


def fetch_github_license(repo: str, token):
    """Return a CycloneDX licenses list for a GitHub repo, using a cache."""
    if repo in _license_cache:
        return _license_cache[repo]

    url = f"https://api.github.com/repos/{repo}"
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    if token:
        req.add_header("Authorization", f"Bearer {token}")

    licenses = []
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
            spdx = (data.get("license") or {}).get("spdx_id")
            if spdx and spdx != "NOASSERTION":
                licenses = [{"license": {"id": spdx}}]
    except urllib.error.HTTPError as e:
        if e.code == 403:
            print(f"  [warn] GitHub API rate-limited or forbidden for {repo}", file=sys.stderr)
        elif e.code != 404:
            print(f"  [warn] HTTP {e.code} fetching license for {repo}", file=sys.stderr)
    except Exception as e:
        print(f"  [warn] Could not fetch license for {repo}: {e}", file=sys.stderr)

    _license_cache[repo] = licenses
    return licenses


def fetch_rubygems_license(name: str) -> list:
    """Return a CycloneDX licenses list for a Ruby gem via the RubyGems API."""
    cache_key = f"gem:{name}"
    if cache_key in _license_cache:
        return _license_cache[cache_key]

    url = f"https://rubygems.org/api/v1/gems/{name}.json"
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/json")

    licenses = []
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
            spdx_list = data.get("licenses") or []
            licenses = [{"license": {"id": spdx}} for spdx in spdx_list if spdx]
    except urllib.error.HTTPError as e:
        if e.code != 404:
            print(f"  [warn] HTTP {e.code} fetching RubyGems license for {name}", file=sys.stderr)
    except Exception as e:
        print(f"  [warn] Could not fetch RubyGems license for {name}: {e}", file=sys.stderr)

    _license_cache[cache_key] = licenses
    return licenses


def enrich_with_licenses(bom: dict) -> int:
    """Add license info to all components via GitHub API (Swift/Carthage) or RubyGems API (gems)."""
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        print("  [warn] GITHUB_TOKEN not set; unauthenticated requests are rate-limited to 60/hour")

    enriched = 0
    for comp in bom.get("components", []):
        if comp.get("licenses"):
            continue

        purl = comp.get("purl", "")
        if purl.startswith("pkg:gem/"):
            licenses = fetch_rubygems_license(comp.get("name", ""))
        else:
            repo = extract_github_repo(comp)
            if not repo:
                continue
            licenses = fetch_github_license(repo, token)

        if licenses:
            comp["licenses"] = licenses
            enriched += 1
        time.sleep(0.05)

    return enriched


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

    print("\nParsing Gemfile.lock...")
    gems = parse_gemfile_lock()
    if gems:
        print(f"  Found {len(gems)} Ruby gem(s)")
        extra.extend(gems)
    else:
        print("  Nothing found.")

    print(f"\nMerging {len(extra)} extra component(s) into bom.json...")
    added, total = merge_into_bom(extra)

    print("\nEnriching components with license information from GitHub API...")
    with open(OUTPUT) as f:
        bom = json.load(f)
    enriched = enrich_with_licenses(bom)
    with open(OUTPUT, "w") as f:
        json.dump(bom, f, indent=2)
    print(f"  Enriched {enriched} component(s) with license data")

    print(f"\nDone. Added {added} component(s). Total components in SBOM: {total}")
    print(f"Output: {OUTPUT}")


if __name__ == "__main__":
    main()
