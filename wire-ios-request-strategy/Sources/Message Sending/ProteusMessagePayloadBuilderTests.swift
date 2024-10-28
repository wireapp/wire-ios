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
import WireRequestStrategySupport

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
        let message = GenericMessage(content: Text(content: "test"))
        try await internalTestEncryptForTransport(genericMessage: message, qualifiedIds: true)
    }

    func testEncryptForTransportUsingQualifiedIds() async throws {
        let message = GenericMessage(content: Text(content: "test"))
        try await internalTestEncryptForTransport(genericMessage: message, qualifiedIds: true)
    }

    func testEncryptForTransportEphemeralMessage() async throws {
        let message = GenericMessage(content: Ephemeral(content: Text(content: "test"), expiresAfter: .fiveMinutes))
        try await internalTestEncryptForTransport(genericMessage: message)
    }

    func testThatCreatesEncryptedDataAndAddsItToGenericMessageAsBlob() async throws {
        // GIVEN
        let message = GenericMessage(content: Text(content: self.stringLargeEnoughToRequireExternal), nonce: UUID())

        // WHEN
        let data = try await internalTestEncryptForTransport(genericMessage: message, qualifiedIds: false)

        // THEN
        let createdMessage = try Proteus_NewOtrMessage.with {
            try $0.merge(serializedData: data)
        }

        XCTAssertEqual(createdMessage.hasBlob, true)
        let clientIds = createdMessage.recipients.flatMap { userEntry -> [Proteus_ClientId] in
            return (userEntry.clients).map { clientEntry -> Proteus_ClientId in
                return clientEntry.client
            }
        }
        let clientSet = Set(clientIds)
        XCTAssertEqual(clientSet.count, 1)
    }

    func testThatCorruptedClientsReceiveBogusPayloadWhenSentAsExternal() async throws {

        // GIVEN
        let userAID = QualifiedID.random()
        let userBID = QualifiedID.random()
        let clientAID = String.randomClientIdentifier()
        let clientBID = String.randomClientIdentifier()
        let domain = String.randomDomain()
        let sessionAID: ProteusSessionID = .init(domain: domain,
                                                userID: userAID.uuid.uuidString,
                                                clientID: clientAID)

        let sessionBID: ProteusSessionID = .init(domain: domain,
                                                userID: userBID.uuid.uuidString,
                                                clientID: clientBID)

        let listClients: MessageInfo.ClientList = [
            userAID.domain: [
                userAID.uuid: [
                    UserClientData(sessionID: sessionAID)
                ],

                userBID.uuid: [
                    UserClientData(sessionID: sessionBID, data: ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8)!)
                ]
            ]
        ]

        let message = GenericMessage(content: Text(content: self.stringLargeEnoughToRequireExternal), nonce: UUID())

        // WHEN
        let data = try await internalTestEncryptForTransport(genericMessage: message,
                                                             qualifiedIds: false,
                                                             listClients: listClients)

        // THEN
        let createdMessage = try Proteus_NewOtrMessage.with {
            try $0.merge(serializedData: data)
        }
        XCTAssertEqual(createdMessage.hasBlob, true)

        let userEntry = try  XCTUnwrap(createdMessage.recipients.first { $0.user.uuid == userBID.uuid.uuidData })

        XCTAssertEqual(userEntry.clients.count, 1)
        let client = try XCTUnwrap(userEntry.clients.first)
        XCTAssertEqual(String(data: client.text, encoding: .utf8), ZMFailedToCreateEncryptedMessagePayloadString)
    }

    // MARK: - Helpers

    @discardableResult
    private func internalTestEncryptForTransport(genericMessage: GenericMessage,
                                                 qualifiedIds: Bool = true,
                                                 listClients: MessageInfo.ClientList,
                                                 file: StaticString = #filePath,
                                                 line: UInt = #line) async throws -> Data {

        proteusService.encryptBatchedDataForSessions_MockMethod = { data, sessions in
            var result = [String: Data]()
            sessions.forEach { session in
                result[session.rawValue] = data
            }
            return result
        }

        sut = ProteusMessagePayloadBuilder(proteusService: proteusService, useQualifiedIds: qualifiedIds)
        let messageInfo = MessageInfo(genericMessage: genericMessage,
                                      listClients: listClients,
                                      missingClientsStrategy: .doNotIgnoreAnyMissingClient,
                                      selfClientID: .randomClientIdentifier())

        // WHEN
        let data = try await sut.encryptForTransport(with: messageInfo)

        // THEN
        XCTAssertNotNil(data, file: file, line: line)
        return data
    }

    @discardableResult
    private func internalTestEncryptForTransport(genericMessage: GenericMessage,
                                                 qualifiedIds: Bool = true,
                                                 file: StaticString = #filePath,
                                                 line: UInt = #line) async throws -> Data {
        // GIVEN
        let userID = QualifiedID.random()
        let clientID = String.randomClientIdentifier()
        let sessionID: ProteusSessionID = .init(domain: .randomDomain(),
                                                userID: userID.uuid.uuidString,
                                                clientID: clientID)
        let listClients: MessageInfo.ClientList = [
            userID.domain: [
                userID.uuid: [
                    UserClientData(sessionID: sessionID)
                ]
            ]
        ]
        return try await internalTestEncryptForTransport(genericMessage: genericMessage,
                                                         qualifiedIds: qualifiedIds,
                                                         listClients: listClients,
                                                         file: file,
                                                         line: line)
    }

    /// Returns a string large enough to have to be encoded in an external message
    fileprivate var stringLargeEnoughToRequireExternal: String {
        var text = "Hello"
        while text.data(using: .utf8)!.count < Int(ZMClientMessage.byteSizeExternalThreshold) {
            text.append(text)
        }
        return text
    }
}
