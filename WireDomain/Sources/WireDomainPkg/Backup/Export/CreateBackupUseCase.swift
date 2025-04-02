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
public import WireLogging

@preconcurrency import WireBackup

public struct CreateBackupUseCase: CreateBackupUseCaseProtocol {

    let fileArchiver: any ExportBackupFileArchiverProtocol
    let currentDateProvider: any CurrentDateProviding
    let selfUserID: QualifiedID
    // let logger: any LoggerProtocol // TODO: fix Sendable error

    public init(
        fileArchiver: any ExportBackupFileArchiverProtocol,
        currentDateProvider: any CurrentDateProviding,
        // TODO: inject the persistent container or any CoreData context
        // TODO: inject the self user id
        selfUserID: QualifiedID,
        logger: any LoggerProtocol
    ) {
        self.fileArchiver = fileArchiver
        self.currentDateProvider = currentDateProvider
        self.selfUserID = selfUserID
        // self.logger = logger
    }

    public func invoke(password: String) -> AsyncThrowingStream<CreateBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> {
                do {

                    continuation.yield(.progress(0))

                    // TODO: use logger
                    // logger.debug("creating backup ...")

                    let backupExporter = MPBackupExporter(
                        selfUserId: BackupQualifiedId(selfUserID),
                        workDirectory: "TODO-0", // TODO: pass temporary directory URL
                        outputDirectory: "TODO-1", // TODO: pass temporary directory URL
                        fileZipper: ExportBackupFileZipper2FileZipperAdapter(
                            fileManager: .default,
                            fileArchiver: fileArchiver,
                            currentDateProvider: currentDateProvider
                        )
                    )

                    // TODO: fetch form CoreData and call these methods:
                    // backupExporter.add(user: <#T##BackupUser#>)
                    // backupExporter.add(message: <#T##BackupMessage#>)
                    // backupExporter.add(conversation: <#T##BackupConversation#>)

                    // TODO: report accurate progress
                    continuation.yield(.progress(0.25))

                    // TODO: then finalize:
                    // try await backupExporter.finalize(password: password)

                    // TODO: send correct URL
                    continuation.yield(.done(URL(fileURLWithPath: "", isDirectory: false)))
                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
