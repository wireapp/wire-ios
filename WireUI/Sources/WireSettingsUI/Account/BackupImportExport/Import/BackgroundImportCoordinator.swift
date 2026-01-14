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
/// with the app lifecycle.
///
@MainActor
final class BackgroundImportCoordinator: BackgroundImportCoordinatorProtocol {

    // MARK: - Dependencies

    private let importUseCaseFactory: any ImportBackupUseCaseFactoryProtocol
    private let logger: WireLogger

    // MARK: - State

    private var currentBackgroundTask: UIBackgroundTaskIdentifier?
    private var currentImportTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        importUseCaseFactory: any ImportBackupUseCaseFactoryProtocol,
        logger: WireLogger = WireLogger(tag: "backup")
    ) {
        self.importUseCaseFactory = importUseCaseFactory
        self.logger = logger
    }

    // MARK: - Interface

    /// Starts a new import with background continuation support
    ///
    /// - Parameters:
    ///   - url: URL to the backup file (temporary copy created by ViewModel)
    ///   - password: Password for encrypted backups (empty string if unencrypted)
    /// - Returns: An async throwing stream of import progress events
    ///
    func startImport(
        for url: URL,
        password: String?
    ) -> AsyncThrowingStream<ImportBackupProgress, any Error> {

        // Start background activity
        startBackgroundTask()

        logger.info("starting import with background continuation support", attributes: .safePublic)
        
        // Create a stream that wraps the use case stream and manages background activity
        return AsyncThrowingStream { continuation in
            currentImportTask = Task {
                do {
                    // Create use case with the provided URL
                    let useCase = try importUseCaseFactory.importBackupUseCase(for: url)

                    // Stream progress from use case
                    for try await progress in useCase.invoke(password: password ?? "") {
                        continuation.yield(progress)

                        if case .done = progress {
                            logger.info("import completed successfully", attributes: .safePublic)
                            endBackgroundTask()
                            continuation.finish()
                            break
                        }
                    }
                } catch is CancellationError {
                    endBackgroundTask()
                    continuation.finish()
                } catch {
                    logger.error("import failed: \(error)")
                    endBackgroundTask()
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

        endBackgroundTask()
    }

    // MARK: - Private Methods

    private func startBackgroundTask() {
        // End any existing task first
        endBackgroundTask()

        currentBackgroundTask = UIApplication.shared.beginBackgroundTask(
            withName: "Backup Import"
        ) { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleBackgroundExpiration()
            }
        }
    }

    private func endBackgroundTask() {
        guard let task = currentBackgroundTask, task != .invalid else { return }

        UIApplication.shared.endBackgroundTask(task)
        currentBackgroundTask = nil
    }

    private func handleBackgroundExpiration() {
        logger.info("background import task expired", attributes: .safePublic)
        // Only end the iOS background task
        // The Swift Task will naturally suspend and resume with app lifecycle
        endBackgroundTask()
    }
}
