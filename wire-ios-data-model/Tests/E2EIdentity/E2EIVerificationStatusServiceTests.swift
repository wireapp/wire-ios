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

@testable import WireDataModel
@testable import WireDataModelSupport

class E2EIVerificationStatusServiceTests: XCTestCase {

    var sut: E2EIVerificationStatusService!
    var mockCoreCryptoContext: MockCoreCryptoContextProtocol!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!

    override func setUp() {
        super.setUp()

        mockCoreCryptoContext = MockCoreCryptoContextProtocol()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCryptoContext: mockCoreCryptoContext)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = mockSafeCoreCrypto
        sut = E2EIVerificationStatusService(coreCryptoProvider: mockCoreCryptoProvider)
    }

    override func tearDown() {
        mockCoreCryptoContext = nil
        mockSafeCoreCrypto = nil
        mockCoreCryptoProvider = nil

        sut = nil

        super.tearDown()
    }

    // MARK: - Get conversation verification status

    func test_GetConversationStatus_IsSuccessful() async throws {
        // Given
        let groupID = MLSGroupID.random()
        mockCoreCryptoContext.e2eiConversationStateConversationId_MockMethod = { _ in
            .verified
        }

        // When
        let conversationStatus = try await sut.getConversationStatus(groupID: groupID)

        // Then
        XCTAssertEqual(conversationStatus, .verified)
    }

}
