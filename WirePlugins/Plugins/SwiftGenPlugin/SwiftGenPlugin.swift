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
import PackagePlugin

@main
struct SwiftGenPlugin: BuildToolPlugin {
    /// Entry point for creating build commands for targets in Swift packages.
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // regarding the warning: https://github.com/swiftlang/swift-package-manager/issues/7870
        let configFileURL = target.directoryURL.appending(path: ".swiftgen.yml", directoryHint: .notDirectory)
        let outputFilesDirectoryURL = context.pluginWorkDirectoryURL
        let tool = try context.tool(named: "swiftgen")
        return [
            .prebuildCommand(
                displayName: "Running \(tool)",
                executable: tool.url,
                arguments: ["--config", configFileURL.path()],
                environment: ["GENERATED": outputFilesDirectoryURL.path()],
                outputFilesDirectory: outputFilesDirectoryURL
            )
        ]
    }
}
