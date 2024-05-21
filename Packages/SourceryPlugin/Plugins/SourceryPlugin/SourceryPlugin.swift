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
struct SourceryPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PackagePlugin.PluginContext,
        target: PackagePlugin.Target
    ) async throws -> [PackagePlugin.Command] {

        print("SourceryPlugin work directory: \(context.pluginWorkDirectory)")

        // Possible paths where there may be a config file (root of package, target dir.)
        let configurations: [Path] = [context.package.directory, target.directory]
            .map { $0.appending(".sourcery.yml") }
            .filter { FileManager.default.fileExists(atPath: $0.string) }

        // Validate paths list
        guard
            validate(configurations: configurations, targetName: target.name),
            let configuration = configurations.first
        else {
            return []
        }

        return [
            .prebuildCommand(
                displayName: "Execute Sourcery",
                executable: try context.tool(named: "sourcery").path,
                arguments: [
                    "--config",
                    configuration.string,
                    "--cacheBasePath",
                    context.pluginWorkDirectory
                ],
                environment: [
                    "DERIVED_SOURCES_DIR": context.pluginWorkDirectory
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }

    func validate(configurations: [Path], targetName: String) -> Bool {
        guard !configurations.isEmpty else {
            Diagnostics.error(
"""
No configurations found for target \(targetName). If you would like to generate sources for this \
target include a `.sourcery.yml` in the target's source directory, or include a shared `.sourcery.yml` at the \
package's root.
"""
            )
            return false
        }

        return true
    }
}
