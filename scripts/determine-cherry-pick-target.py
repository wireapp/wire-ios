#!/usr/bin/env python3
"""
Determine the target branch for cherry-picking from a release branch.

This script:
1. If the input branch is one of the tracked release branches (LTS_RELEASE or
   GOV_RELEASE env vars, e.g. release/cycle-4.16), targets 'develop' directly,
   skipping future release branches
2. Gets all release branches matching release/cycle-* pattern
3. Sorts them by version number (major.minor)
4. Finds the position of the input branch in the sorted list
5. Selects the next branch in the sorted list, or 'develop' if no next branch exists

Usage:
    python3 scripts/determine-cherry-pick-target.py <base_branch>

Output:
    Writes the target branch to GITHUB_OUTPUT environment file.
"""

import os
import re
import subprocess
import sys


def version_key(branch):
    """Extract version from release/cycle-X.Y pattern and return as tuple for sorting."""
    match = re.search(r'release/cycle-(\d+)\.(\d+)', branch)
    if match:
        return (int(match.group(1)), int(match.group(2)))
    # Fallback: sort lexicographically
    return (0, 0)


def get_release_branches():
    """Get all remote branches matching release/cycle-* pattern."""
    result = subprocess.run(
        ["git", "ls-remote", "--heads", "origin"],
        capture_output=True,
        text=True
    )
    
    branches = []
    for line in result.stdout.strip().split('\n'):
        if line:
            # Format: <hash> refs/heads/release/cycle-X.Y
            parts = line.split()
            if len(parts) >= 2:
                branch = parts[1].replace('refs/heads/', '')
                if branch.startswith('release/cycle-'):
                    branches.append(branch)
    
    return branches


def determine_target_branch(base_branch):
    """Determine the target branch for cherry-picking."""
    # Check if base branch matches release/cycle-* pattern
    if not base_branch.startswith("release/cycle-"):
        print(f"Base branch {base_branch} doesn't match release/cycle-* pattern, using develop")
        return "develop"

    # If the base branch is one of the tracked release branches (LTS or GOV),
    # skip future release branches and cherry-pick straight to develop.
    for env_var in ("LTS_RELEASE", "GOV_RELEASE"):
        tracked_release = os.environ.get(env_var, "").strip()
        if tracked_release and base_branch == tracked_release:
            print(f"Base branch {base_branch} is the {env_var} release branch, using develop")
            return "develop"
    
    # Get all release branches
    branches = get_release_branches()
    
    if not branches:
        print(f"No release branches found, using develop")
        return "develop"
    
    # Sort branches by version number
    branches.sort(key=version_key)
    
    print(f"Found {len(branches)} release branches:")
    for branch in branches:
        print(f"  - {branch}")
    
    # Find the position of the base branch
    try:
        index = branches.index(base_branch)
        print(f"\nBase branch {base_branch} found at position {index + 1} of {len(branches)}")
        
        # Get the next branch
        if index + 1 < len(branches):
            next_branch = branches[index + 1]
            print(f"Next release branch: {next_branch}")
            return next_branch
        else:
            print(f"No next release branch found, using develop")
            return "develop"
    except ValueError:
        print(f"Base branch {base_branch} not found in release branches, using develop")
        return "develop"


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/determine-cherry-pick-target.py <base_branch>", file=sys.stderr)
        sys.exit(1)
    
    base_branch = sys.argv[1]
    target_branch = determine_target_branch(base_branch)
    
    # Write output to GITHUB_OUTPUT file
    github_output = os.environ.get('GITHUB_OUTPUT')
    if github_output:
        with open(github_output, 'a') as f:
            f.write(f"target={target_branch}\n")
    else:
        # Fallback: print to stdout if not in GitHub Actions
        print(f"target={target_branch}")


if __name__ == "__main__":
    main()
