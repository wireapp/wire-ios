//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - SourceryPlugin

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

// MARK: BuildToolPlugin

extension SourceryPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PackagePlugin.PluginContext,
        target: PackagePlugin.Target
    ) async throws -> [PackagePlugin.Command] {
        Diagnostics.remark("SourceryPlugin work directory: \(context.pluginWorkDirectory)")

        // Find configuration from possible paths where there may be a config file:
        // 1. root of package
        // 2. target directory
        // 3. target directory subfolder named 'Sourcery'
        let configuration = [
            context.package.directory,
            target.directory,
            target.directory.appending(subpath: "/Sourcery"),
        ]
        .map { $0.appending(Constant.configFileName) }
        .filter { FileManager.default.fileExists(atPath: $0.string) }
        .first

        guard let configuration else {
            Diagnostics.error("""
            No configurations found for target \(target.name). If you would like to generate sources for this \
            target include a `\(Constant.configFileName)` either in:
            1. root of package
            2. target directory
            3. target directory subfolder named 'Sourcery'
            """)
            return []
        }

        return try [
            makePrebuildCommand(
                context: context,
                configuration: configuration,
                targetDirectory: target.directory
            ),
        ]
    }

    private func makePrebuildCommand(
        context: PackagePlugin.PluginContext,
        configuration: Path,
        targetDirectory: Path
    ) throws -> PackagePlugin.Command {
        try .prebuildCommand(
            displayName: Constant.displayName,
            executable: context.tool(named: Constant.toolName).path,
            arguments: [
                "--config",
                configuration.string,
                "--cacheBasePath",
                context.pluginWorkDirectory,
            ],
            environment: [
                Constant.Environment.derivedSourcesDirectory: context.pluginWorkDirectory,
                Constant.Environment.packageRootDirectory: context.package.directory,
                Constant.Environment.targetDirectory: targetDirectory.string,
            ],
            outputFilesDirectory: context.pluginWorkDirectory
        )
    }
}
