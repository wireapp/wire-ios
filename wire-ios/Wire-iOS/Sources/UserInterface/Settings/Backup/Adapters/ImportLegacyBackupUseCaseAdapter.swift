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

import Foundation
import WireDomainPackage
import WireBackup
import WireSettingsUI

// These adapters are required because TODO: finish

struct ImportLegacyBackupUseCaseAdapter: WireBackup.ImportBackupUseCaseProtocol {

    let importBackupUseCase: WireDomainPackage.ImportBackupUseCaseProtocol

    init(_ importBackupUseCase: WireDomainPackage.ImportBackupUseCaseProtocol) {
        self.importBackupUseCase = importBackupUseCase
    }

    func invoke(url: URL, password: String) -> AsyncThrowingStream<WireBackup.ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> {
                do {
                    for try await update in importBackupUseCase.invoke(url: url, password: password) {
                        switch update {
                        case let .progress(current, total):
                            continuation.yield(.progress(current, total))
                        case .done:
                            continuation.yield(.done)
                        }
                    }
                    continuation.finish()
                } catch let error as WireSettingsUI.ImportBackupError {
                    continuation.finish(throwing: WireBackup.ImportBackupError(error))
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

extension WireBackup.ImportBackupProgress {

    init(_ result: WireDomainPackage.ImportBackupProgress) {
        switch result {
        case let .progress(current, total):
            self = .progress(current, total)
        case .done:
            self = .done
        }
    }
}

extension WireBackup.ImportBackupError {

    init(_ error: WireSettingsUI.ImportBackupError) {
        switch error {
//        case .noActiveAccountForImport:
//            self = .noActiveAccountForImport
        case .passwordRequired:
            self = .passwordRequired
        case .incompatibleFileFormat:
            self = .incompatibleFileFormat
//        case .invalidAccountID:
//            self = .invalidAccountID
//        case .compressionError:
//            self = .compressionError
        case .invalidFileExtension:
            self = .invalidFileExtension
//        case .keyCreationFailed:
//            self = .keyCreationFailed
//        case .decryptionError:
//            self = .decryptionError
//        case .failedToBackUpUserClient:
//            self = .failedToBackUpUserClient
//        case .failedToCreateStreamForDecryption:
//            self = .failedToCreateStreamForDecryption
        }
    }
}
