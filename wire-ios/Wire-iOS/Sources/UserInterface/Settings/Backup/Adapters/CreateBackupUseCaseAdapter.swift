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

import WireBackup
import WireDomainPackage
import WireSettingsUI
import WireSyncEngine

// These adapters are required because TODO: finish

struct CreateBackupUseCaseAdapter: WireSettingsUI.CreateBackupUseCaseProtocol {

    let createBackupUseCase: WireBackup.CreateBackupUseCaseProtocol

    init(_ createBackupUseCase: WireBackup.CreateBackupUseCaseProtocol) {
        self.createBackupUseCase = createBackupUseCase
    }

    func invoke(password: String) -> AsyncThrowingStream<WireSettingsUI.CreateBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> {
                do {
                    for try await update in createBackupUseCase.invoke(password: password) {
                        switch update {
                        case let .progress(current, total):
                            continuation.yield(.progress(current, total))
                        case .done(let url):
                            continuation.yield(.done(url))
                        }
                    }
                    continuation.finish()
                } catch let error as WireSyncEngine.CreateBackupError { // TODO: map errors
                    continuation.finish(throwing: WireSettingsUI.CreateBackupError(error))
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /*
}

extension WireSettingsUI.CreateBackupProgress {

    init(_ result: WireSyncEngine.CreateBackupProgress) {
        switch result {
        case let .progress(value):
            self = .progress(value)
        case .done:
            self = .done
        }
    }
}

extension WireSettingsUI.CreateLegacyBackupError {

    init(_ error: WireSyncEngine.CreateLegacyBackupError) {
        switch error {
        case .noActiveAccountForCreate:
            self = .noActiveAccountForCreate
        case .passwordRequired:
            self = .passwordRequired
        case .incompatibleFileFormat:
            self = .incompatibleFileFormat
        case .invalidAccountID:
            self = .invalidAccountID
        case .compressionError:
            self = .compressionError
        case .invalidFileExtension:
            self = .invalidFileExtension
        case .keyCreationFailed:
            self = .keyCreationFailed
        case .decryptionError:
            self = .decryptionError
        case .failedToBackUpUserClient:
            self = .failedToBackUpUserClient
        case .failedToCreateStreamForDecryption:
            self = .failedToCreateStreamForDecryption
        }
    }
 */
}
