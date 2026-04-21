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

// sourcery: AutoMockable
public protocol RemoveEARKeysUseCaseProtocol {

    /// Removes all encryption at rest keys from the keychain for the given account.
    func invoke(accountID: UUID)

}

public struct RemoveEARKeysUseCase: RemoveEARKeysUseCaseProtocol {

    private let keyRepository: EARKeyRepositoryInterface

    public init() {
        self.keyRepository = EARKeyRepository()
    }

    init(keyRepository: EARKeyRepositoryInterface) {
        self.keyRepository = keyRepository
    }

    // MARK: - Public interface

    public func invoke(accountID: UUID) {
        EARKeyDescription.allCases.forEach { key in
            deleteKey(key, accountID: accountID)
        }
    }

    // MARK: - Helpers

    private func deleteKey(_ key: EARKeyDescription, accountID: UUID) {
        do {
            switch key {
            case .primaryPublic:
                try keyRepository.deletePublicKey(description: .primaryKeyDescription(accountID: accountID))
            case .primaryPrivate:
                try keyRepository.deletePrivateKey(description: .primaryKeyDescription(
                    accountID: accountID,
                    context: nil
                ))
            case .secondaryPublic:
                try keyRepository.deletePublicKey(description: .secondaryKeyDescription(accountID: accountID))
            case .secondaryPrivate:
                try keyRepository.deletePrivateKey(description: .secondaryKeyDescription(accountID: accountID))
            case .database:
                try keyRepository.deleteDatabaseKey(description: .keyDescription(accountID: accountID))
            }
        } catch {
            WireLogger.ear.error(
                "failed to remove \(key.rawValue) key for accountID: \(accountID) - error: \(String(describing: error))"
            )
        }
    }

    private enum EARKeyDescription: String, CaseIterable {
        case primaryPublic
        case primaryPrivate
        case secondaryPublic
        case secondaryPrivate
        case database
    }

}
