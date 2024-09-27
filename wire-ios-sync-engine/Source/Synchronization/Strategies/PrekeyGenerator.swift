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
import WireCryptobox

class PrekeyGenerator {
    // MARK: Lifecycle

    init(proteusProvider: ProteusProviding) {
        self.proteusProvider = proteusProvider
    }

    // MARK: Internal

    // This is needed to save ~3 seconds for every unit test run
    // as generating 100 keys is an expensive operation
    static var _test_overrideNumberOfKeys: UInt16?

    let proteusProvider: ProteusProviding
    let keyCount: UInt16 = _test_overrideNumberOfKeys ?? 100

    func generatePrekeys(startIndex: UInt16 = 0) async throws -> [IdPrekeyTuple] {
        try await proteusProvider.performAsync(
            withProteusService: { proteusService in
                try await proteusService.generatePrekeys(start: startIndex, count: keyCount)
            },
            withKeyStore: { keyStore in
                try keyStore.generateMoreKeys(keyCount, start: startIndex)
            }
        )
    }

    func generateLastResortPrekey() async throws -> IdPrekeyTuple {
        try await proteusProvider.performAsync(
            withProteusService: { proteusService in
                try await (
                    id: proteusService.lastPrekeyID,
                    prekey: proteusService.lastPrekey()
                )
            },
            withKeyStore: { keyStore in
                try (
                    id: CBOX_LAST_PREKEY_ID,
                    prekey: keyStore.lastPreKey()
                )
            }
        )
    }
}
