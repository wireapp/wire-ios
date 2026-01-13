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
import WireFoundation

import UIKit

/// Coordinates background import operations.
///
/// Manages the iOS background task lifecycle to allow imports to continue
/// when the app is backgrounded. The Swift Task naturally suspends and resumes
/// with the app lifecycle - no manual persistence or resume logic needed.
@MainActor
final class BackgroundImportCoordinator {

    // MARK: - Dependencies

    private let importUseCaseFactory: any ImportBackupUseCaseFactoryProtocol
    private let logger: WireLogger
    private let fileManager: FileManager

    // MARK: - State

    private var currentBackgroundActivity: BackgroundActivity?
    private var currentImportTask: Task<Void, Never>?
    private var currentBackupCopy: URL?

    // MARK: - Initialization

    init(
        importUseCaseFactory: any ImportBackupUseCaseFactoryProtocol,
        fileManager: FileManager = .default,
        logger: WireLogger = WireLogger(tag: "backup")
    ) {
        self.importUseCaseFactory = importUseCaseFactory
        self.fileManager = fileManager
        self.logger = logger
    }

    // MARK: - Interface

    /// Starts a new import with background continuation support
    ///
    /// - Parameters:
    ///   - url: URL to the backup file from file picker
    ///   - password: Password for encrypted backups (empty string if unencrypted)
    /// - Returns: An async throwing stream of import progress events
    ///
    func startImport(
        for url: URL,
        password: String?
    ) -> AsyncThrowingStream<ImportBackupProgress, any Error> {

        // Start background activity
        startBackgroundActivity()

        // Create a stream that wraps the use case stream and manages background activity + file lifecycle
        return AsyncThrowingStream { continuation in
            currentImportTask = Task {
                defer {
                    // Clean up the temporary copy when done
                    cleanupBackupCopy()
                }

                do {
                    // Generate temporary copy for import
                    let copy = try await generateFileCopy(for: url)
                    currentBackupCopy = copy

                    // Create use case with the copy
                    let useCase = try importUseCaseFactory.importBackupUseCase(for: copy)

                    // Stream progress from use case
                    for try await progress in useCase.invoke(password: password ?? "") {
                        continuation.yield(progress)

                        if case .done = progress {
                            endBackgroundActivity()
                            continuation.finish()
                            break
                        }
                    }
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    logger.error("Import failed: \(error)")
                    endBackgroundActivity()
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.currentImportTask?.cancel()
                }
            }
        }
    }

    /// Cancels the current import
    func cancelImport() {
        currentImportTask?.cancel()
        currentImportTask = nil

        endBackgroundActivity()
        cleanupBackupCopy()
    }

    // MARK: - Private Methods

    private func startBackgroundActivity() {
        // End any existing activity first
        if let activity = currentBackgroundActivity {
            BackgroundActivityFactory.shared.endBackgroundActivity(activity)
        }

        currentBackgroundActivity = BackgroundActivityFactory.shared.startBackgroundActivity(
            name: "Backup Import"
        ) { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleBackgroundExpiration()
            }
        }
    }

    private func endBackgroundActivity() {
        guard let activity = currentBackgroundActivity else { return }

        BackgroundActivityFactory.shared.endBackgroundActivity(activity)
        currentBackgroundActivity = nil
    }

    private func handleBackgroundExpiration() {
        // Only end the iOS background task
        // The Swift Task will naturally suspend and resume with app lifecycle
        endBackgroundActivity()
    }

    // MARK: - File Management

    private func generateFileCopy(for url: URL) async throws -> URL {
        let localURL = try await materializeURL(url)
        let gotAccess = localURL.startAccessingSecurityScopedResource()
        // let the file manager throw the error in case `gotAccess` is `false`.

        let tmpDirectory = try fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: localURL,
            create: true
        )
        let copy = tmpDirectory.appendingPathComponent(localURL.lastPathComponent)

        try fileManager.copyItem(at: localURL, to: copy)
        if gotAccess {
            localURL.stopAccessingSecurityScopedResource()
        }

        return copy
    }

    // Materialize the url if needed. If we picked from iCloud
    // then it should already be downloaded and available locally,
    // but this may not be the case for other file providers such
    // as Google Drive.
    private func materializeURL(_ url: URL) async throws -> URL {
        let task = Task.detached {
            try await withCheckedThrowingContinuation { continuation in
                let coordinator = NSFileCoordinator()
                var error: NSError?

                coordinator.coordinate(
                    readingItemAt: url,
                    options: [],
                    error: &error
                ) {
                    continuation.resume(returning: $0)
                }

                // The completion is not called if there's an error, so we need
                // to check it here.
                if let error {
                    continuation.resume(throwing: error)
                }
            }
        }

        return try await task.value
    }

    private func cleanupBackupCopy() {
        guard let copy = currentBackupCopy else { return }

        do {
            try fileManager.removeItem(at: copy)
        } catch {
            logger.warn("Failed to cleanup backup file copy: \(error)")
        }

        currentBackupCopy = nil
    }
}
