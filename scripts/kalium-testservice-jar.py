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
import hashlib
import json
import os
import re
import shutil
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

DEFAULT_REPOSITORY = "wireapp/kalium"
TAG_RE = re.compile(r"^test-service-v(\d+)\.(\d+)\.(\d+)$")
JAR_RE = re.compile(r"^testservice-.*-all\.jar$")


def get_json(url):
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "wire-ios-kalium-testservice",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"

    last_error = None
    request = urllib.request.Request(url, headers=headers)
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if 400 <= error.code < 500 and error.code != 429:
                raise RuntimeError(f"GitHub API request failed: {url} ({error.code})")
            last_error = f"HTTP {error.code}"
        except urllib.error.URLError as error:
            last_error = str(error.reason)

        if attempt < 2:
            time.sleep(2)

    raise RuntimeError(f"GitHub API request failed after retries: {url} ({last_error})")


def testservice_jar(release):
    jars = [
        asset for asset in release.get("assets", [])
        if asset.get("state") == "uploaded" and JAR_RE.match(asset.get("name", ""))
    ]
    return jars[0] if len(jars) == 1 else None


def release_info(release, asset):
    return {
        "ref": release["tag_name"],
        "asset_name": asset["name"],
        "asset_url": asset["browser_download_url"],
        "asset_digest": asset.get("digest") or "",
        "asset_size": str(asset.get("size") or ""),
    }


def resolve_release(ref, repository):
    api = f"https://api.github.com/repos/{repository}/releases"

    if ref:
        if not TAG_RE.match(ref):
            raise RuntimeError(f"Invalid Kalium testservice ref: {ref}")

        print(f"Resolving Kalium Testservice release: {ref}")
        release = get_json(f"{api}/tags/{ref}")
        asset = testservice_jar(release)
        if not asset:
            raise RuntimeError(f"Release {ref} has no unique testservice fat jar")
        return release_info(release, asset)

    print("Resolving latest Kalium Testservice release with a fat jar")
    best = None
    for page in range(1, 11):
        releases = get_json(f"{api}?per_page=100&page={page}")
        if not releases:
            break

        for release in releases:
            match = TAG_RE.match(release.get("tag_name", ""))
            asset = testservice_jar(release)
            if not match or not asset:
                continue

            version = tuple(int(part) for part in match.groups())
            if best is None or version > best[0]:
                best = (version, release, asset)

    if best is None:
        raise RuntimeError("No Kalium testservice release with a fat jar found")

    return release_info(best[1], best[2])


def cache_key(info):
    digest = info.get("asset_digest", "")
    if digest.startswith("sha256:"):
        return digest.replace(":", "-")

    return f"{info.get('ref', 'unknown')}-{info.get('asset_size', 'unknown')}"


def write_outputs(info, jar_path=None, path=None):
    if not path:
        return

    values = dict(info)
    values["cache_key"] = cache_key(info)
    if jar_path:
        values["jar_path"] = str(jar_path)

    with open(path, "a", encoding="utf-8") as output:
        for key, value in values.items():
            output.write(f"{key}={value}\n")


def file_sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def jar_is_current(path, info):
    if not path.is_file():
        return False

    digest = info.get("asset_digest", "")
    if digest.startswith("sha256:"):
        return file_sha256(path) == digest.removeprefix("sha256:")

    size = info.get("asset_size")
    if size:
        return path.stat().st_size == int(size)

    return path.stat().st_size > 0


def download(url, path):
    headers = {"User-Agent": "wire-ios-kalium-testservice"}
    request = urllib.request.Request(url, headers=headers)
    last_error = None

    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                with open(path, "wb") as file:
                    shutil.copyfileobj(response, file, length=1024 * 1024)
            return
        except (urllib.error.HTTPError, urllib.error.URLError) as error:
            last_error = str(error)
            path.unlink(missing_ok=True)

        if attempt < 2:
            time.sleep(2)

    raise RuntimeError(f"Jar download failed after retries: {last_error}")


def ensure_jar(info, output):
    output.parent.mkdir(parents=True, exist_ok=True)

    if jar_is_current(output, info):
        print(f"Using cached Kalium Testservice jar: {output}")
        return

    temp = output.with_name(f"{output.name}.download")
    output.unlink(missing_ok=True)
    temp.unlink(missing_ok=True)

    print(f"Downloading Kalium Testservice jar: {info['asset_name']}")
    download(info["asset_url"], temp)

    if not jar_is_current(temp, info):
        temp.unlink(missing_ok=True)
        raise RuntimeError("Downloaded Kalium Testservice jar failed verification")

    temp.replace(output)
    print(f"Using jar: {output}")


def parse_args():
    parser = argparse.ArgumentParser(description="Download the Kalium Testservice fat jar.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    resolve = subparsers.add_parser("resolve")
    resolve.add_argument("--repository", default=DEFAULT_REPOSITORY)
    resolve.add_argument("--ref", default="")
    resolve.add_argument("--github-output", default=os.environ.get("GITHUB_OUTPUT"))

    download_cmd = subparsers.add_parser("download")
    download_cmd.add_argument("--repository", default=DEFAULT_REPOSITORY)
    download_cmd.add_argument("--ref", default="")
    download_cmd.add_argument("--asset-name", default="")
    download_cmd.add_argument("--asset-url", default="")
    download_cmd.add_argument("--asset-digest", default="")
    download_cmd.add_argument("--asset-size", default="")
    download_cmd.add_argument("--github-output", default=os.environ.get("GITHUB_OUTPUT"))
    download_cmd.add_argument("--output", required=True)

    return parser.parse_args()


def main():
    args = parse_args()

    if args.command == "resolve":
        info = resolve_release(args.ref, args.repository)
        print(f"Using Kalium Testservice ref: {info['ref']}")
        print(f"Using Kalium Testservice asset: {info['asset_name']}")
        write_outputs(info, path=args.github_output)
        return

    if args.asset_url:
        info = {
            "ref": args.ref,
            "asset_name": args.asset_name or Path(args.asset_url).name,
            "asset_url": args.asset_url,
            "asset_digest": args.asset_digest,
            "asset_size": args.asset_size,
        }
    else:
        info = resolve_release(args.ref, args.repository)

    output = Path(args.output)
    print(f"Using Kalium Testservice ref: {info['ref']}")
    print(f"Using Kalium Testservice asset: {info['asset_name']}")
    ensure_jar(info, output)
    write_outputs(info, jar_path=output, path=args.github_output)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
