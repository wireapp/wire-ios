//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import PackagePlugin

@main
struct SourceryPlugin {

    private enum Constant {
        enum Environment {
            static let derivedSourcesDirectory = "DERIVED_SOURCES_DIR"
            static let packageRootDirectory = "PACKAGE_ROOT_DIR"
            static let targetDirectory = "TARGET_DIR"
        }

        static let displayName = "Execute Sourcery"
        static let toolName = "sourcery"

        static let configFileName = "sourcery.yml"
    }
}

// MARK: - BuildToolPlugin

extension SourceryPlugin: BuildToolPlugin {

    func createBuildCommands(
        context: PackagePlugin.PluginContext,
        target: PackagePlugin.Target
    ) async throws -> [PackagePlugin.Command] {
        Diagnostics.remark("SourceryPlugin work directory: \(context.pluginWorkDirectoryURL.path())")

        // Find configuration from possible paths where there may be a config file:
        // 1. root of package
        // 2. target directory
        // 3. target directory subfolder named 'Sourcery'
        let configURL = [
            context.package.directoryURL,
            target.directoryURL,
            target.directoryURL.appending(path: "Sourcery", directoryHint: .isDirectory)
        ]
        .map { (url: URL) in url.appending(path: Constant.configFileName, directoryHint: .notDirectory) }
        .filter { url in FileManager.default.fileExists(atPath: url.path()) }
        .first

        guard let configURL else {
            Diagnostics.error(
                """
                No configurations found for target \(target.name). If you would like to generate sources for this \
                target include a `\(Constant.configFileName)` either in:
                1. root of package
                2. target directory
                3. target directory subfolder named 'Sourcery'
                """
            )
            return []
        }

        return [
            try makePrebuildCommand(
                context: context,
                configURL: configURL,
                targetDirectoryURL: target.directoryURL
            )
        ]
    }

    private func makePrebuildCommand(
        context: PackagePlugin.PluginContext,
        configURL: URL,
        targetDirectoryURL: URL
    ) throws -> PackagePlugin.Command {
        .prebuildCommand(
            displayName: Constant.displayName,
            executable: try context.tool(named: Constant.toolName).url,
            arguments: [
                "--config",
                configURL.path(),
                "--cacheBasePath",
                context.pluginWorkDirectoryURL.path()
            ],
            environment: [
                Constant.Environment.derivedSourcesDirectory: context.pluginWorkDirectoryURL.path(),
                Constant.Environment.packageRootDirectory: context.package.directoryURL.path(),
                Constant.Environment.targetDirectory: targetDirectoryURL.path()
            ],
            outputFilesDirectory: context.pluginWorkDirectoryURL
        )
    }
}
