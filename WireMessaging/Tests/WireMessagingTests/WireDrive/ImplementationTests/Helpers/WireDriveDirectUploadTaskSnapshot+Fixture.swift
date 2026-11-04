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

@testable import WireMessagingData

extension WireDriveDirectUploadTaskSnapshot {

    static func fixture(
        uploadID: UUID? = UUID(),
        taskIdentifier: Int = 1,
        state: State = .running,
        bytesSent: Int64 = 0,
        totalBytes: Int64 = 2048,
        originalURL: URL? = URL(string: "https://example.com/io/cell-1/Documents/report.pdf")
    ) -> Self {
        WireDriveDirectUploadTaskSnapshot(
            uploadID: uploadID,
            taskIdentifier: taskIdentifier,
            state: state,
            bytesSent: bytesSent,
            totalBytes: totalBytes,
            originalURL: originalURL
        )
    }
}
