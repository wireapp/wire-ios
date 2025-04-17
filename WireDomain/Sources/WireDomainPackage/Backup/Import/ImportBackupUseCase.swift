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

public import Foundation
public import WireLogging

@preconcurrency import WireBackup

public struct ImportBackupUseCase: ImportBackupUseCaseProtocol {

    // let context: @Sendable () -> NSManagedObjectContext
    let fileManager: @Sendable () -> FileManager = { .default }
    let logger: @Sendable () -> any LoggerProtocol

    public init(
        logger: @escaping @autoclosure @Sendable () -> any LoggerProtocol
    ) {
        self.logger = logger
    }

    public func invoke(url: URL, password: String) -> AsyncThrowingStream<ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> {

                let fileManager = fileManager()
                let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)

                defer {
                    try? fileManager.removeItem(at: workDirectoryURL)
                }

                do {
                    let logger = logger()
                    logger.debug("initializing MPBackupImporter")
                    let importer = MPBackupImporter(
                        pathToWorkDirectory: workDirectoryURL.path(),
                        backupFileUnzipper: <#T##any BackupFileUnzipper#>
                    )

                    // TODO: implement

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
