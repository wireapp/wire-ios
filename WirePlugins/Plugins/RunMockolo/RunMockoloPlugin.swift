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
struct RunMockoloPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let sourceModule = target.sourceModule else { return [] }
        let generatedSourceURL = context.pluginWorkDirectoryURL.appending(path: "GeneratedMocks.swift")

        return [
            .prebuildCommand(
                displayName: "Run mockolo",
                executable: try context.tool(named: "mockolo").url,
                arguments: [
                    "-s", sourceModule.directoryURL.path(percentEncoded: false),
                    "-d", generatedSourceURL.path(percentEncoded: false),
                ],
                outputFilesDirectory: context.pluginWorkDirectoryURL
            ),
        ]
    }
}
