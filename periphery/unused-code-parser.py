#!/usr/bin/env python3
"""
Parses Xcode build logs to identify and group warnings and errors, generating
structured reports.

This script reads a log file containing output from an Xcode build process,
specifically targeting lines that represent compiler warnings or errors. It intelligently
groups multi-line issue descriptions and organizes them by project and file.

Features:
- Parses file paths, line/column numbers, issue types, and messages.
- Correctly handles multi-line issue descriptions and associated notes.
- Intelligently extracts project names from file paths (e.g., from '/wire-ios/MyProject/...').
- Generates organized Markdown (`.md`) reports, creating a separate file for each project.
- Automatically clears old report files before generating new ones.

Usage:
    ./unused-code-parser.py <path_to_log_file>
"""
import re
import os
import sys
import glob
import argparse
from collections import defaultdict
from dataclasses import dataclass
from typing import Dict, List, Optional
@dataclass
class Issue:
    """Represents a single compiler issue, including its full multi-line message."""
    file_path: str
    line_number: int
    column_number: int
    issue_type: str
    project: str
    full_message: str  # The primary issue line and all subsequent related lines (e.g., notes).

# Type alias for the nested dictionary structure: {project: {file_path: [Issue]}}
GroupedData = Dict[str, Dict[str, List[Issue]]]

# Regex to identify the start of a new issue line and capture its components.
# Group 1: File Path (/path/to/file.swift)
# Group 2: Line Number (123)
# Group 3: Column Number (45)
# Group 4: Issue Type (warning|error)
# Group 5: Message (the rest of the line)
ISSUE_LINE_REGEX = re.compile(r"^/?([^:]+):(\d+):(\d+): (warning|error): (.*)$")

# Patterns to identify log lines that are not part of an issue's description and should be skipped.
IGNORED_LINE_PATTERNS = [
    re.compile(r"^\s*In file included from"),
    re.compile(r"^\s*In module"),
    re.compile(r"^\d+ warnings? generated\.")
]

def extract_project_name(file_path: str) -> str:
    """
    Extracts a project name from a file path.
    
    Args:
        file_path: The full path to the source file.

    Returns:
        The extracted project name, or 'UnknownProject' if the pattern is not found.
    """
    parts = file_path.split('/')

    # Case 1: Path is inside the 'wire-ios' monorepo structure.
    # e.g., 'wire-ios/Wire-iOS/...' -> 'Wire-iOS'
    if 'wire-ios' in parts:
        try:
            wire_ios_index = parts.index('wire-ios')
            if len(parts) > wire_ios_index + 1:
                return parts[wire_ios_index + 1]
        except (ValueError, IndexError):
            pass  # Fallback if the structure is unexpected.

    # Case 2: Path is relative from a module root (e.g., 'WireAnalytics/Sources/...').
    if len(parts) > 1:
        return parts[0]

    return 'UnknownProject'

def parse_log_file(log_path: str) -> GroupedData:
    """ 
    Parses a build log file to identify and group compiler issues.

    This function reads the log line by line, identifies issue headers, and
    groups subsequent related lines (like notes) into a single `Issue` object.

    Args:
        log_path: The path to the log file to parse.
    Returns:
        A nested dictionary grouping issues by project and then by file path.
    """
    # Use defaultdict for convenient initialization of nested structures.
    grouped_issues: GroupedData = defaultdict(lambda: defaultdict(list))
    
    current_issue: Optional[Issue] = None

    try:
        with open(log_path, 'r', encoding='utf-8') as f:
            for line in f:
                # First, check if the line should be ignored.
                if any(pattern.match(line) for pattern in IGNORED_LINE_PATTERNS):
                    continue

                match = ISSUE_LINE_REGEX.match(line)
                
                # This line starts a new issue.
                if match:
                    # A new issue line was found. Create a new Issue object.
                    file_path, line_num, col_num, issue_type, message = match.groups()
                    project = extract_project_name(file_path)
                    
                    current_issue = Issue(
                        file_path=file_path,
                        line_number=int(line_num),
                        column_number=int(col_num),
                        issue_type=issue_type,
                        project=project,
                        full_message=line.strip()  # Start with the first line of the message.
                    )
                    grouped_issues[project][file_path].append(current_issue)
                
                # This line is a continuation of the current issue (e.g., a 'note:').
                elif current_issue and line.strip():
                    # Append this continuation line to the message of the current issue.
                    current_issue.full_message += f"\n{line.strip()}"
                
                else:
                    # If we hit a blank line, it signifies the end of a block.
                    # Reset current_issue to ensure subsequent lines don't get appended incorrectly.
                    current_issue = None

    except FileNotFoundError:
        print(f"Error: Log file not found at '{log_path}'", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)
        
    return grouped_issues

def _generate_project_markdown(project: str, files: Dict) -> str:
    """Generates the Markdown content for a single project."""
    report_lines = [f"# Unused Code Report for Project: `{project}`"]
    for file_path, issues in sorted(files.items()):
        report_lines.append(f"\n### File: `{file_path}`")
        for issue in issues:
            report_lines.append(f"\n- **{issue.issue_type.capitalize()}** at Line {issue.line_number}:{issue.column_number}")
            report_lines.append("\n```log")
            report_lines.append(issue.full_message)
            report_lines.append("```")
    return "\n".join(report_lines)

def generate_markdown_report(grouped_data: GroupedData, output_file: str):
    """
    Generates Markdown reports, creating one file per project.

    Args:
        grouped_data: The dictionary of issues, grouped by project.
        output_file: A path that serves as a template for the output files.
                     For example, 'reports/unused.md' will generate 'reports/unused-ProjectA.md'.
    """
    # Ensure the output directory exists.
    output_dir = os.path.dirname(output_file)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    # Separate the directory, base filename, and extension
    base_name = os.path.basename(output_file)
    base, ext = os.path.splitext(base_name) if base_name else ("unused-code", ".md")

    for project, files in sorted(grouped_data.items()):
        project_filename = os.path.join(output_dir, f"{base}-{project}{ext}")
        report_content = _generate_project_markdown(project, files)
        with open(project_filename, 'w', encoding='utf-8') as f:
            f.write(report_content)
        print(f"Markdown report for '{project}' saved to '{project_filename}'")

def clear_previous_reports(output_template: str):
    """
    Deletes report files from previous runs based on the output template.

    Args:
        output_template: The file path template for reports (e.g., 'reports/unused-code.md').
    """
    # Ensure we look for reports in the correct directory.
    output_dir = os.path.dirname(output_template)
    base_name = os.path.basename(output_template)
    base_filename, ext = os.path.splitext(base_name)

    # Create a glob pattern to find all files from previous runs (e.g., "reports/unused-code-*.md").
    search_pattern = os.path.join(output_dir, f"{base_filename}-*{ext}")
    print(f"Clearing previous reports matching: '{search_pattern}'...")
    for filepath in glob.glob(search_pattern):
        os.remove(filepath)
        print(f"  - Removed '{filepath}'")

def main():
    """Main execution block."""
    parser = argparse.ArgumentParser(description="Parses Xcode build logs to identify and group warnings and errors.")
    parser.add_argument(
        "log_file",
        help="Path to the Xcode build log file to parse."
    )
    
    args = parser.parse_args()
    log_file_path = args.log_file

    # Get the directory where the script is located.
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Define a constant for the output directory, relative to the script's location.
    OUTPUT_DIR = os.path.join(script_dir, 'reports')
    output_file_template = os.path.join(OUTPUT_DIR, 'unused-code.md')

    # Clear old reports before generating new ones if outputting to Markdown.
    clear_previous_reports(output_file_template)

    print(f"Parsing log file: {log_file_path}...")
    grouped_data = parse_log_file(log_file_path)
    
    print("\nGenerating report...")
    generate_markdown_report(grouped_data, output_file_template)

if __name__ == "__main__":
    main()
