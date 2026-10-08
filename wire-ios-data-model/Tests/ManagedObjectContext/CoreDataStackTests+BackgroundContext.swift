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
import Testing

@testable import WireDataModel

@Suite
struct CoreDataStackTests_BackgroundContext {

    @Test(arguments: [
        (localDomain: "example.com", isFederationEnabled: true),
        (localDomain: "example.com", isFederationEnabled: false),
        (localDomain: String?.none, isFederationEnabled: false)
    ])
    func `newBackgroundContext propagates localDomain and isFederationEnabled`(
        localDomain: String?,
        isFederationEnabled: Bool
    ) async throws {
        // GIVEN
        let stack = CoreDataStack(
            account: Account(userName: "", userIdentifier: UUID()),
            applicationContainer: URL.documentsDirectory,
            inMemoryStore: true,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )
        try await stack.load()

        // WHEN
        let context = stack.newBackgroundContext()

        // THEN
        await context.perform {
            #expect(context.localDomain == localDomain)
            #expect(context.isFederationEnabled == isFederationEnabled)
        }
    }
}
