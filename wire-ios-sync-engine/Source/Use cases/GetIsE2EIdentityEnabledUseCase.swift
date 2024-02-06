//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireCoreCrypto

// sourcery: AutoMockable
public protocol GetIsE2EIdentityEnabledUseCaseProtocol {
    func invoke() async throws -> Bool
}

public final class GetIsE2EIdentityEnabledUseCase: GetIsE2EIdentityEnabledUseCaseProtocol {
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    public init(coreCryptoProvider: CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    public func invoke() async throws -> Bool {
        let coreCrypto = try await coreCryptoProvider.coreCrypto(requireMLS: true)
        return try await coreCrypto.perform {
            try await $0.e2eiIsEnabled(ciphersuite: CiphersuiteName.mls128Dhkemx25519Aes128gcmSha256Ed25519.rawValue)
        }
    }
}
