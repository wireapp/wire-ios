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
import WireDomainPkg
import WireSettingsUI

// Instead of linking WireDomainPkg into WireUI targets several symlinks have been created.
// Therefore many types exist twice, once in their original target (WireDomainPkg) and once in WireUI.

// TODO: [WPB-15347] delete this workaround
struct ImportBackupUseCaseProtocolAdapter: WireSettingsUI.ImportBackupUseCaseProtocol {

    private let importBackupUseCaseProtocol: any WireDomainPkg.ImportBackupUseCaseProtocol

    fileprivate init(_ importBackupUseCaseProtocol: any WireDomainPkg.ImportBackupUseCaseProtocol) {
        self.importBackupUseCaseProtocol = importBackupUseCaseProtocol
    }

    func invoke(url: URL, password: String) -> AsyncThrowingStream<WireSettingsUI.ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            Task<Void, Never> {
                do {

                    for try await update in importBackupUseCaseProtocol.invoke(url: url, password: password) {
                        switch update {
                        case let .progress(fraction):
                            continuation.yield(.progress(fraction))
                        case .done:
                            continuation.yield(.done)
                        }
                    }
                    continuation.finish()

                } catch let error as WireDomainPkg.ImportBackupError {
                    switch error {
                    case .noActiveAccount:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.noActiveAccount)
                    case .passwordRequired:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.passwordRequired)
                    case .incompatibleFileFormat:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.incompatibleFileFormat)
                    case .invalidAccountID:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.invalidAccountID)
                    case .compressionError:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.compressionError)
                    case .invalidFileExtension:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.invalidFileExtension)
                    case .keyCreationFailed:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.keyCreationFailed)
                    case .decryptionError:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.decryptionError)
                    case .unknown:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.unknown)
                    }

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

extension WireSettingsUI.ImportBackupUseCaseProtocol where Self == ImportBackupUseCaseProtocolAdapter {
    static func adapter(_ importBackupUseCaseProtocol: (any WireDomainPkg.ImportBackupUseCaseProtocol)?) -> Self {
        .init(importBackupUseCaseProtocol!)
    }
}
