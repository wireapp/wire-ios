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

import WireLogging
@testable import WireSyncEngine

public final class MockLogFilesProviding: LogFilesProviding {

    public var generateLogFilesZip_Invocations: [Void] = []
    public var mockURL: URL?

    public init() {}

    public func generateLogFilesData() throws -> Data {
        Data()
    }

    public func generateLogFilesZip() throws -> URL {
        generateLogFilesZip_Invocations.append(())

        let url = URL(fileURLWithPath: [NSTemporaryDirectory(), UUID().uuidString].joined(separator: "/"))
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
        return mockURL ?? url
    }

    public func clearLogsDirectory() throws {}

    public func removeLogFiles() throws {}

    public func removeLegacyLogArchives() throws {}

}
