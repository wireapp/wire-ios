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

import WireRequestStrategySupport
import WireDataModelSupport

@testable import WireRequestStrategy

final class ProteusMessagePayloadBuilderTests: XCTestCase {
    
    var sut: ProteusMessagePayloadBuilder!
    var proteusService: MockProteusServiceInterface!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        DeveloperFlag.proteusViaCoreCrypto.enable(true, storage: .temporary())
        proteusService = MockProteusServiceInterface()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        proteusService = nil
        sut = nil
    }

    func testEncryptForTransportUsingNonQualifiedIds() async throws {
        try await internalTestEncryptForTransport(qualifiedIds: false)
    }
    
    func testEncryptForTransportUsingQualifiedIds() async throws {
        try await internalTestEncryptForTransport(qualifiedIds: true)
    }
    
    // MARK - helpers
    
    private func internalTestEncryptForTransport(qualifiedIds: Bool) async throws {
        // GIVEN
        let userID = QualifiedID.random()
        let clientID = String.randomClientIdentifier()
        let sessionID: ProteusSessionID = .init(domain: .randomDomain(),
                              userID: userID.uuid.uuidString,
                              clientID: clientID)
        let listClients: MessageInfo.ClientList = [
            userID.domain: [
                userID.uuid : [
                    UserClientData(sessionID: sessionID)
                ]
            ]
        ]
        
        proteusService.encryptBatchedDataForSessions_MockMethod = { _, _ in
            [sessionID.rawValue: Data()]
        }
        
        sut = ProteusMessagePayloadBuilder(proteusService: proteusService, useQualifiedIds: qualifiedIds)
        let messageInfo = MessageInfo(genericMessage: GenericMessage(content: Text(content: "test")),
                                      listClients: listClients,
                                      missingClientsStrategy: .doNotIgnoreAnyMissingClient,
                                      selfClientID: .randomClientIdentifier(),
                                      nativePush: true,
                                      userClients: [])

        // WHEN
        let data = try await sut.encryptForTransport(with: messageInfo)
        
        // THEN
        XCTAssertNotNil(data)
    }
}
