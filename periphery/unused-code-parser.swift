#!/usr/bin/env swift
//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

// MARK: - Data Structures

// Represents a single compiler issue, including its full multi-line message.
struct Issue {
    let filePath: String
    let lineNumber: Int
    let columnNumber: Int
    let issueType: String
    let project: String
    var fullMessage: String // Mutable to append subsequent related lines (e.g., notes).
}

// Type alias for the nested dictionary structure: [Project: [File Path: [Issue]]]
typealias FileIssues = [String: [Issue]]
typealias GroupedData = [String: FileIssues]

// MARK: - Constants and Regex

let ISSUE_LINE_PATTERN = "^/?([^:]+):(\\d+):(\\d+): (warning|error): (.*)$"
let IGNORED_LINE_PATTERNS = [
    try! NSRegularExpression(pattern: "^\\s*In file included from", options: []),
    try! NSRegularExpression(pattern: "^\\s*In module", options: []),
    try! NSRegularExpression(pattern: "^\\d+ warnings? generated\\.")
]

/// Extracts a project name from a file path based on common repository and module structures.
///
/// - Parameter filePath: The full path to the source file.
/// - Returns: The extracted project name, or 'UnknownProject'.
func extractProjectName(from filePath: String) -> String {
    let parts = filePath.components(separatedBy: "/")

    // Case 1: Path is inside the 'wire-ios' monorepo structure.
    // e.g., 'wire-ios/Wire-iOS/...' -> 'Wire-iOS'
    if let wireIosIndex = parts.firstIndex(of: "wire-ios"),
       parts.indices.contains(wireIosIndex + 1) {
        return parts[wireIosIndex + 1]
    }

    // Case 2: Path is relative from a module root (e.g., 'WireAnalytics/Sources/...').
    // Ensure the first component is not empty (i.e., not an absolute path like /A/B/C)
    if parts.count > 1, let firstPart = parts.first, !firstPart.isEmpty {
        return firstPart
    }

    return "UnknownProject"
}

/// Attempts to match a line against the primary issue regex pattern.
///
/// - Parameter line: The line of text to match.
/// - Returns: A tuple containing the captured groups, or nil if no match is found.
func matchIssueLine(line: String) ->
    (filePath: String, lineNum: String, colNum: String, type: String, message: String)? {
    guard let regex = try? NSRegularExpression(pattern: ISSUE_LINE_PATTERN, options: []),
          let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) else {
        return nil
    }

    let nsString = line as NSString
    // Group 1: File Path, 2: Line, 3: Column, 4: Type, 5: Message
    let capturedGroups = (1...5).map { nsString.substring(with: match.range(at: $0)) }

    return (capturedGroups[0], capturedGroups[1], capturedGroups[2], capturedGroups[3], capturedGroups[4])
}

/// Parses a build log file to identify and group compiler issues.
///
/// - Parameter logPath: The path to the log file to parse.
/// - Throws: An error if the file cannot be read.
/// - Returns: A nested dictionary grouping issues by project and then by file path.
func parseLogFile(at logPath: String) throws -> GroupedData {
    guard let fileContents = try? String(contentsOfFile: logPath, encoding: .utf8) else {
        throw NSError(domain: "LogParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Log file not found or could not be read at '\(logPath)'"])
    }

    var groupedIssues: GroupedData = [:]
    var currentIssue: Issue?

    let lines = fileContents.components(separatedBy: .newlines)

    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Check if the line should be ignored (e.g., 'In file included from...')
        if IGNORED_LINE_PATTERNS.contains(where: { $0.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) != nil }) {
            continue
        }

        // 2. Check for a new issue header line
        if let match = matchIssueLine(line: line) {
            // A new issue line was found. Create a new Issue object.
            let project = extractProjectName(from: match.filePath)

            currentIssue = Issue(
                filePath: match.filePath,
                lineNumber: Int(match.lineNum) ?? 0,
                columnNumber: Int(match.colNum) ?? 0,
                issueType: match.type,
                project: project,
                fullMessage: trimmedLine // Start with the first line of the message
            )

            // Initialize the nested dictionaries if necessary and append the new issue.
            groupedIssues[project, default: [:]][match.filePath, default: []].append(currentIssue!)
        }

        // 3. Check for a continuation line of the current issue (e.g., a 'note:')
        else if currentIssue != nil && !trimmedLine.isEmpty {
            // Append this continuation line to the message of the current issue.
            currentIssue!.fullMessage += "\n\(trimmedLine)"
        }

        // 4. Blank line signifies the end of an issue block
        else {
            currentIssue = nil
        }
    }

    return groupedIssues
}

/// Generates the Markdown content for a single project.
///
/// - Parameters:
///   - project: The name of the project.
///   - files: A dictionary of issues grouped by file path.
/// - Returns: The complete Markdown content string.
func generateProjectMarkdown(project: String, files: FileIssues) -> String {
    var reportLines = ["# Unused Code Report for Project: `\(project)`"]

    // Sort files by path for consistent output
    let sortedFiles = files.sorted { $0.key < $1.key }

    for (filePath, issues) in sortedFiles {
        reportLines.append("\n### File: `\(filePath)`")

        // Sort issues by line number
        for issue in issues.sorted(by: { $0.lineNumber < $1.lineNumber }) {
            reportLines.append("\n- **\(issue.issueType.capitalized)** at Line \(issue.lineNumber):\(issue.columnNumber)")
            reportLines.append("\n```log")
            reportLines.append(issue.fullMessage)
            reportLines.append("```")
        }
    }
    return reportLines.joined(separator: "\n")
}

/// Deletes report files from previous runs based on the output template.
///
/// - Parameter outputTemplate: The file path template for reports (e.g., 'reports/unused-code.md').
/// - Throws: An error if a file cannot be removed.
func clearPreviousReports(outputTemplate: String) throws {
    let fileManager = FileManager.default
    let outputURL = URL(fileURLWithPath: outputTemplate)
    let outputDirURL = outputURL.deletingLastPathComponent()

    let baseName = outputURL.lastPathComponent
    let base = URL(fileURLWithPath: baseName).deletingPathExtension().lastPathComponent
    let ext = outputURL.pathExtension

    // The search pattern for files created by this script is: baseName-ProjectName.ext
    let reportSearchPrefix = "\(base)-"
    let reportSearchSuffix = ".\(ext)"

    print("Clearing previous reports matching: '\(outputDirURL.path)/\(reportSearchPrefix)*\(reportSearchSuffix)'...")

    // Ensure directory exists before listing contents
    if fileManager.fileExists(atPath: outputDirURL.path) {
        let contents = try fileManager.contentsOfDirectory(atPath: outputDirURL.path)

        for filename in contents {
            if filename.hasPrefix(reportSearchPrefix) && filename.hasSuffix(reportSearchSuffix) {
                let fullPath = outputDirURL.appendingPathComponent(filename).path
                try fileManager.removeItem(atPath: fullPath)
                print("  - Removed '\(fullPath)'")
            }
        }
    }
}

/// Generates Markdown reports, creating one file per project.
///
/// - Parameters:
///   - groupedData: The dictionary of issues, grouped by project.
///   - outputFileTemplate: A path that serves as a template for the output files.
func generateMarkdownReport(groupedData: GroupedData, outputFileTemplate: String) throws {
    let fileManager = FileManager.default
    let outputURL = URL(fileURLWithPath: outputFileTemplate)
    let outputDirURL = outputURL.deletingLastPathComponent()

    // 1. Ensure the output directory exists.
    if !fileManager.fileExists(atPath: outputDirURL.path) {
        try fileManager.createDirectory(at: outputDirURL, withIntermediateDirectories: true)
    }

    let baseName = outputURL.lastPathComponent
    let base = URL(fileURLWithPath: baseName).deletingPathExtension().lastPathComponent
    let ext = outputURL.pathExtension.isEmpty ? "md" : outputURL.pathExtension

    // Sort projects alphabetically for consistent output
    for (project, files) in groupedData.sorted(by: { $0.key < $1.key }) {
        let projectFilename = "\(base)-\(project).\(ext)"
        let projectFileUrl = outputDirURL.appendingPathComponent(projectFilename)

        let reportContent = generateProjectMarkdown(project: project, files: files)

        try reportContent.write(to: projectFileUrl, atomically: true, encoding: .utf8)
        print("Markdown report for '\(project)' saved to '\(projectFileUrl.path)'")
    }
}

// MARK: - Main Execution

// Get the path to the executable script
let scriptPath = CommandLine.arguments[0]
let scriptDir = URL(fileURLWithPath: scriptPath).deletingLastPathComponent().path

// Define constants for output relative to the script's location
let outputDir = (scriptDir as NSString).appendingPathComponent("reports")
let outputFileTemplate = (outputDir as NSString).appendingPathComponent("unused-code.md")

// Check for required argument
guard CommandLine.arguments.count > 1 else {
    print("Usage: \(scriptPath) <path_to_log_file>")
    exit(1)
}

let logFilePath = CommandLine.arguments[1]

do {
    // Clear old reports before generating new ones
    try clearPreviousReports(outputTemplate: outputFileTemplate)

    print("Parsing log file: \(logFilePath)...")
    let groupedData = try parseLogFile(at: logFilePath)

    print("\nGenerating report...")
    try generateMarkdownReport(groupedData: groupedData, outputFileTemplate: outputFileTemplate)

} catch {
    // Print the localized description of the error
    print("An error occurred: \(error.localizedDescription)")
    exit(1)
}
