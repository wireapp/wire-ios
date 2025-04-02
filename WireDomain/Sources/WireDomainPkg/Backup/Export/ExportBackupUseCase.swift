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

public import WireAPI
public import WireFoundation

@preconcurrency import WireBackup

public struct ExportBackupUseCase: ExportBackupUseCaseProtocol {

//     let mpBackupExporter: MPBackupExporter
    let fileArchiver: any ExportBackupFileArchiverProtocol
    let currentDateProvider: any CurrentDateProviding
    // TODO: peristence container or context

    public init(
        fileArchiver: any ExportBackupFileArchiverProtocol,
        currentDateProvider: any CurrentDateProviding
    ) {
        self.fileArchiver = fileArchiver
        self.currentDateProvider = currentDateProvider
    }

    public func invoke(
        selfUserID: QualifiedID
    ) async throws {
        fatalError("TODO")

        let backupExporter = MPBackupExporter(
            selfUserId: BackupQualifiedId(selfUserID),
            workDirectory: "TODO0",
            outputDirectory: "TODO1",
            fileZipper: ExportBackupFileZipper2FileZipperAdapter(
                fileManager: .default,
                fileArchiver: fileArchiver,
                currentDateProvider: currentDateProvider
            )
        )

        // backupExporter.add(user: <#T##BackupUser#>)
        // backupExporter.add(message: <#T##BackupMessage#>)
        // backupExporter.add(conversation: <#T##BackupConversation#>)
        // try await backupExporter.finalize(password: <#T##String?#>)
    }
}
