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

import WireSettingsUI
import WireSyncEngine

// These adapters are required because WireSyncEngine is an Xcode project and contains the protocol, result+error types
// and the implementation of the `ImportBackupUseCaseProtocol` while WireUI is a Swift package and cannot depend on
// Xcode projects. Therefore the types are duplicated and these adapters bridge from WireSyncEngine to
// WireSettingsUI.

struct ImportBackupUseCaseAdapter: WireSettingsUI.ImportBackupUseCaseProtocol {

    let importBackupUseCase: WireSyncEngine.ImportBackupUseCaseProtocol

    init(_ importBackupUseCase: WireSyncEngine.ImportBackupUseCaseProtocol) {
        self.importBackupUseCase = importBackupUseCase
    }

    func invoke(url: URL, password: String) -> AsyncThrowingStream<WireSettingsUI.ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> {
                do {
                    for try await update in importBackupUseCase.invoke(url: url, password: password) {
                        switch update {
                        case let .progress(fraction):
                            continuation.yield(.progress(fraction))
                        case .done:
                            continuation.yield(.done)
                        }
                    }
                    continuation.finish()
                } catch let error as WireSyncEngine.ImportLegacyBackupError {
                    continuation.finish(throwing: WireSettingsUI.ImportLegacyBackupError(error))
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

extension WireSettingsUI.ImportBackupProgress {

    init(_ result: WireSyncEngine.ImportBackupProgress) {
        switch result {
        case let .progress(value):
            self = .progress(value)
        case .done:
            self = .done
        }
    }
}

extension WireSettingsUI.ImportLegacyBackupError {

    init(_ error: WireSyncEngine.ImportLegacyBackupError) {
        switch error {
        case .noActiveAccountForImport:
            self = .noActiveAccountForImport
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
}
