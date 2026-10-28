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

@testable import WireMessagingDomain

extension WireDriveDirectUploadRecord {

    static func fixture(
        uploadID: UUID = UUID(),
        batchID: UUID = UUID(),
        nodeID: UUID = UUID(),
        versionID: UUID = UUID(),
        destinationFolderPath: String = "cell-1/Documents",
        nodePath: String = "cell-1/Documents/report.pdf",
        fileName: String = "report.pdf",
        fileSize: UInt64 = 2048,
        mimeType: String? = "application/pdf",
        stagedFileName: String = "staged-report.pdf",
        state: WireDriveDirectUploadRecord.State = .staged,
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
        updatedAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
        attemptCount: Int = 0,
        presignedURL: URL? = nil,
        presignedURLExpiresAt: Date? = nil,
        failure: WireDriveUploadError? = nil
    ) -> Self {
        WireDriveDirectUploadRecord(
            uploadID: uploadID,
            batchID: batchID,
            nodeID: nodeID,
            versionID: versionID,
            destinationFolderPath: destinationFolderPath,
            nodePath: nodePath,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            stagedFileName: stagedFileName,
            state: state,
            createdAt: createdAt,
            updatedAt: updatedAt,
            attemptCount: attemptCount,
            presignedURL: presignedURL,
            presignedURLExpiresAt: presignedURLExpiresAt,
            failure: failure
        )
    }
}
