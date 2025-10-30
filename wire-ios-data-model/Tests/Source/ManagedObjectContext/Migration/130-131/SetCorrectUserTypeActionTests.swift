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

import WireDataModelSupport
import XCTest

@testable import WireDataModel

final class SetCorrectUserTypeActionTests: XCTestCase {

    func testSettingValueForUserType() async throws {
        // Given
        let stack = try await CoreDataStackHelper().createStack(inMemoryStore: true)
        let syncContext = stack.syncContext
        try await syncContext.perform { [syncContext] in

            let regularID = QualifiedID(uuid: UUID(), domain: "wire.com")
            let serviceID = QualifiedID(uuid: UUID(), domain: "wire.com")
            do {
                let regularUser = ZMUser.fetchOrCreate(with: regularID.uuid, domain: regularID.domain, in: syncContext)
                regularUser.type = .app // must be `.regular` later
                let serviceUser = ZMUser.fetchOrCreate(with: serviceID.uuid, domain: serviceID.domain, in: syncContext)
                serviceUser.type = .app // must be `.bot` later
                serviceUser.providerIdentifier = "lorem"
                serviceUser.serviceIdentifier = "ipsum"
                try syncContext.save()
            }

            // When
            let sut = SetCorrectUserTypeAction()
            sut.execute(in: syncContext)

            // Then
            let regularUser = ZMUser.fetch(with: regularID.uuid, domain: regularID.domain, in: syncContext)
            XCTAssertEqual(regularUser?.type, .regular)
            let serviceUser = ZMUser.fetch(with: serviceID.uuid, domain: serviceID.domain, in: syncContext)
            XCTAssertEqual(serviceUser?.type, .bot)
        }

    }

}
