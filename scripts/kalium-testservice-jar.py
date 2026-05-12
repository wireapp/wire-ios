#!/usr/bin/env python3

#
# Wire
# Copyright (C) 2026 Wire Swiss GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
#

import argparse
import json
import os
import re
import shutil
import sys
import urllib.request
from pathlib import Path

REPOSITORY = "wireapp/kalium"
RELEASE_RE = re.compile(r"^test-service-v(\d+)\.(\d+)\.(\d+)$")
JAR_RE = re.compile(r"^testservice-.*-all\.jar$")
USER_AGENT = "wire-ios-kalium-testservice"


def github_json(url):
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": USER_AGENT,
    }

    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"

    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def testservice_jar(release):
    jars = [
        asset for asset in release.get("assets", [])
        if asset.get("state") == "uploaded" and JAR_RE.match(asset.get("name", ""))
    ]
    return jars[0] if len(jars) == 1 else None


def release_info(release, asset):
    ref = release["tag_name"]
    asset_id = str(asset["id"])

    return {
        "ref": ref,
        "asset_id": asset_id,
        "asset_name": asset["name"],
        "cache_key": f"{ref}-{asset_id}",
        "download_url": asset["browser_download_url"],
    }


def release_from_ref(api, ref):
    if not RELEASE_RE.match(ref):
        raise RuntimeError(f"Invalid Kalium Testservice ref: {ref}")

    print(f"Resolving Kalium Testservice release: {ref}")
    release = github_json(f"{api}/tags/{ref}")
    asset = testservice_jar(release)
    if not asset:
        raise RuntimeError(f"Release {ref} has no unique testservice fat jar")
    return release_info(release, asset)


def release_candidate(release):
    match = RELEASE_RE.match(release.get("tag_name", ""))
    asset = testservice_jar(release)
    if not match or not asset:
        return None

    version = tuple(int(part) for part in match.groups())
    return version, release, asset


def latest_testservice_release(api):
    latest = None

    for page in range(1, 11):
        releases = github_json(f"{api}?per_page=100&page={page}")
        if not releases:
            break

        for release in releases:
            candidate = release_candidate(release)
            if candidate and (latest is None or candidate[0] > latest[0]):
                latest = candidate

    if latest is None:
        raise RuntimeError("No Kalium Testservice release with a fat jar found")

    return release_info(latest[1], latest[2])


def resolve_release(ref):
    api = f"https://api.github.com/repos/{REPOSITORY}/releases"

    if ref:
        return release_from_ref(api, ref)

    print("Resolving latest Kalium Testservice release")
    return latest_testservice_release(api)


def download_jar(info, jar_path):
    jar_path.parent.mkdir(parents=True, exist_ok=True)
    marker_path = jar_path.parent / "testservice.jar.version"

    if jar_path.is_file() and jar_path.stat().st_size > 0 and marker_path.is_file():
        marker = marker_path.read_text(encoding="utf-8").strip()
        if marker == info["cache_key"]:
            print(f"Using cached Kalium Testservice jar: {jar_path}")
            return

    temp_path = jar_path.parent / "testservice.jar.download"
    temp_path.unlink(missing_ok=True)

    print(f"Downloading Kalium Testservice jar: {info['asset_name']}")
    request = urllib.request.Request(
        info["download_url"],
        headers={"User-Agent": USER_AGENT},
    )

    with urllib.request.urlopen(request, timeout=120) as response:
        with open(temp_path, "wb") as file:
            shutil.copyfileobj(response, file, length=1024 * 1024)

    if temp_path.stat().st_size == 0:
        temp_path.unlink(missing_ok=True)
        raise RuntimeError("Downloaded Kalium Testservice jar is empty")

    temp_path.replace(jar_path)
    marker_path.write_text(f"{info['cache_key']}\n", encoding="utf-8")
    print(f"Using jar: {jar_path}")


def write_outputs(info, jar_path):
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return

    output_values = {
        "ref": info["ref"],
        "asset_id": info["asset_id"],
        "asset_name": info["asset_name"],
        "cache_key": info["cache_key"],
    }

    if jar_path:
        output_values["jar_path"] = str(jar_path)

    with open(output_path, "a", encoding="utf-8") as output:
        for key, value in output_values.items():
            output.write(f"{key}={value}\n")


def parse_args():
    parser = argparse.ArgumentParser(description="Download the Kalium Testservice jar.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    resolve = subparsers.add_parser("resolve")
    resolve.add_argument("--ref", default="")

    download = subparsers.add_parser("download")
    download.add_argument("--ref", default="")
    download.add_argument("--output", required=True)

    return parser.parse_args()


def main():
    args = parse_args()
    info = resolve_release(args.ref)

    print(f"Using Kalium Testservice ref: {info['ref']}")
    print(f"Using Kalium Testservice asset: {info['asset_name']}")

    jar_path = None
    if args.command == "download":
        jar_path = Path(args.output)
        download_jar(info, jar_path)

    write_outputs(info, jar_path)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
