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
import WireLogging
import ZIPFoundation

// sourcery: AutoMockable
protocol CreateDebugReportUseCaseProtocol {
    func invoke() async throws -> URL
    func invokeData() async throws -> Data
}

final class CreateDebugReportUseCase: CreateDebugReportUseCaseProtocol {

    enum UseCaseError: Error {
        case noLogs(description: String)
    }

    private let logsProvider: LogFilesProviding
    private let selfUserID: UUID?

    init(logsProvider: LogFilesProviding = LogFilesProvider(), selfUserID: UUID?) {
        self.logsProvider = logsProvider
        self.selfUserID = selfUserID
    }

    func invoke() async throws -> URL {
        try await withCheckedThrowingContinuation { [logsProvider, selfUserID] continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try Self.createZip(
                        logsProvider: logsProvider,
                        selfUserID: selfUserID
                    ))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func invokeData() async throws -> Data {
        let url = try await invoke()
        return try await Task.detached(priority: .userInitiated) {
            defer { try? FileManager.default.removeItem(at: url) }
            return try Data(contentsOf: url)
        }.value
    }

    // MARK: - Private

    private static func createZip(logsProvider: LogFilesProviding, selfUserID: UUID?) throws -> URL {
        let fileManager = FileManager.default
        let logsDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("logs", isDirectory: true)

        try? fileManager.removeItem(at: logsDirectory)

        let logFileURLs = logsProvider.logFileURLs
        guard !logFileURLs.isEmpty else {
            throw UseCaseError.noLogs(description: logFileURLs.description)
        }

        try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        let archiveFolder = logsDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: archiveFolder, withIntermediateDirectories: true)

        let info = logsProvider.info(selfUserID: selfUserID)
        let infoFileURL = archiveFolder.appendingPathComponent("info.txt")
        try info.write(to: infoFileURL, atomically: true, encoding: .utf8)

        for url in logFileURLs {
            let copy = archiveFolder.appending(path: url.lastPathComponent, directoryHint: .notDirectory)
            try fileManager.copyItem(at: url, to: copy)
        }

        let zipURL = logsDirectory.appendingPathComponent("logs.zip")
        try fileManager.zipItem(at: archiveFolder, to: zipURL, shouldKeepParent: false, compressionMethod: .deflate)
        try fileManager.removeItem(at: archiveFolder)

        return zipURL
    }
}
