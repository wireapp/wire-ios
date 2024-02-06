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

import WireDataModelSupport
import XCTest

@testable import WireSyncEngine

final class HasSelfUserValidE2EICertificatesForAllClientsUseCaseTests: ZMBaseManagedObjectTest {

    var sut: HasSelfUserValidE2EICertificatesForAllClientsUseCase!
    var coreCryptoProvider: CoreCryptoProviderProtocol!

    override func setUp() {
        coreCryptoProvider = MockCoreCryptoProviderProtocol()
        sut = .init(
            context: NSManagedObjectContext,
            coreCryptoProvider: coreCryptoProvider
        )
    }

    override func tearDown() {
        sut = nil
        coreCryptoProvider = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
}
