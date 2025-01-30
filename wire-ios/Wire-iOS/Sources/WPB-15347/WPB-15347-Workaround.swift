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
import WireDomainPkg
import Foundation

// TODO: [WPB-15347] delete this workaround
struct ImportBackupUseCaseProtocolAdapter: WireSettingsUI.ImportBackupUseCaseProtocol {

    private let importBackupUseCaseProtocol: any WireDomainPkg.ImportBackupUseCaseProtocol

    fileprivate init(_ importBackupUseCaseProtocol: any WireDomainPkg.ImportBackupUseCaseProtocol) {
        self.importBackupUseCaseProtocol = importBackupUseCaseProtocol
    }

    func invoke(url: URL, password: String) async throws {
        do {
            try await importBackupUseCaseProtocol.invoke(url: url, password: password)
        } catch let error as WireDomainPkg.ImportBackupError {
            switch error {
            case .noActiveAccount:
                throw WireSettingsUI.ImportBackupError.noActiveAccount
            case .passwordRequired:
                throw WireSettingsUI.ImportBackupError.passwordRequired
            case .compressionError:
                throw WireSettingsUI.ImportBackupError.compressionError
            case .invalidFileExtension:
                throw WireSettingsUI.ImportBackupError.invalidFileExtension
            case .keyCreationFailed:
                throw WireSettingsUI.ImportBackupError.keyCreationFailed
            case .decryptionError:
                throw WireSettingsUI.ImportBackupError.decryptionError
            case .unknown:
                throw WireSettingsUI.ImportBackupError.unknown
            }
        }
    }
}

extension WireSettingsUI.ImportBackupUseCaseProtocol where Self == ImportBackupUseCaseProtocolAdapter {
    static func adapter(_ importBackupUseCaseProtocol: (any WireDomainPkg.ImportBackupUseCaseProtocol)?) -> Self {
        .init(importBackupUseCaseProtocol!)
    }
}
