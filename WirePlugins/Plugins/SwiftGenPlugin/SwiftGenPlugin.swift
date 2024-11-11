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
struct SwiftGenPlugin: BuildToolPlugin {
    /// Entry point for creating build commands for targets in Swift packages.
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // regarding the warning: https://github.com/swiftlang/swift-package-manager/issues/7870
        let configFile = URL(fileURLWithPath: target.directory.appending(subpath: "swiftgen.yml").string)
        let outputFilesDirectory = context.pluginWorkDirectoryURL
        let tool = try context.tool(named: "swiftgen")
        return [
            .prebuildCommand(
                displayName: "Running \(tool)",
                executable: tool.url,
                arguments: ["--config", configFile.path()],
                environment: ["GENERATED": outputFilesDirectory.path()],
                outputFilesDirectory: outputFilesDirectory
            ),
            /// This workaround is needed because at the time of writing `strings/structured-swift5.stencil` of SwiftGen does not support existential any.
            try existentialAnyWorkaround(context: context)
        ]
    }

    private func existentialAnyWorkaround(context: PluginContext) throws -> Command {
        let outputFilesDirectory = context.pluginWorkDirectoryURL
        let outputFile = outputFilesDirectory.appending(path: "Strings+Generated.swift", directoryHint: .notDirectory)

        return .prebuildCommand(
            displayName: "Replace CVarArg by any CVarArg",
            executable: try context.tool(named: "sed").url,
            arguments: ["-i.bak", "s/CVarArg/any CVarArg/", outputFile.path()],
            outputFilesDirectory: outputFilesDirectory
        )
    }
}
