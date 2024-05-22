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

@main
struct SourceryPlugin {

    private enum Constant {
        enum Arguments {
            static let config = "config"
            static let cacheBasePath = "cacheBasePath"
        }

        enum Environment {
            static let derivedSourcesDirectory = "DERIVED_SOURCES_DIR"
        }

        static let displayName = "Execute Sourcery"
        static let toolName = "sourcery"

        static let configFileName = ".sourcery.yml"
    }
}

// MARK: - BuildToolPlugin

extension SourceryPlugin: BuildToolPlugin {

    func createBuildCommands(
        context: PackagePlugin.PluginContext,
        target: PackagePlugin.Target
    ) async throws -> [PackagePlugin.Command] {

        debugPrint("SourceryPlugin work directory: \(context.pluginWorkDirectory)")

        // Find configuration from possible paths where there may be a config file:
        // 1. root of package
        // 2. target directory
        let configuration = [
            context.package.directory,
            target.directory
        ]
            .map { $0.appending(Constant.configFileName) }
            .filter { FileManager.default.fileExists(atPath: $0.string) }
            .first

        guard let configuration else {
            Diagnostics.error(
"""
No configurations found for target \(target.name). If you would like to generate sources for this \
target include a `.sourcery.yml` in the target's source directory, or include a shared `.sourcery.yml` at the \
package's root.
"""
            )
            return []
        }

        return [
            try makePrebuildCommand(context: context, configuration: configuration)
        ]
    }

    private func makePrebuildCommand(
        context: PackagePlugin.PluginContext,
        configuration: Path
    ) throws -> PackagePlugin.Command {
        .prebuildCommand(
            displayName: Constant.displayName,
            executable: try context.tool(named: Constant.toolName).path,
            arguments: [
                "--\(Constant.Arguments.config)",
                configuration.string,
                "--\(Constant.Arguments.cacheBasePath)",
                context.pluginWorkDirectory
            ],
            environment: [
                Constant.Environment.derivedSourcesDirectory: context.pluginWorkDirectory
            ],
            outputFilesDirectory: context.pluginWorkDirectory
        )
    }
}
