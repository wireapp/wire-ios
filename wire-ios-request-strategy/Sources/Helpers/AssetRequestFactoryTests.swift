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

import WireTesting
@testable import WireRequestStrategy

class AssetRequestFactoryTests: MessagingTestBase {

    func testThatItReturnsExpiringForRegularConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: coreDataStack.viewContext)

        // when & then
        XCTAssertEqual(AssetRequestFactory.Retention(conversation: conversation), .expiring)
    }

    func testThatItReturnsEternalInfrequentAccessForTeamUserConversation() {
        let moc = coreDataStack.syncContext
        moc.performGroupedBlock {
            // given
            let conversation = ZMConversation.insertNewObject(in: moc)
            let team = Team.insertNewObject(in: moc)
            team.remoteIdentifier = .init()

            // when
            let selfUser = ZMUser.selfUser(in: moc)
            let membership = Member.getOrUpdateMember(for: selfUser, in: team, context: moc)
            XCTAssertNotNil(membership.team)
            XCTAssertTrue(selfUser.hasTeam)

            // then
            XCTAssertEqual(AssetRequestFactory.Retention(conversation: conversation), .eternalInfrequentAccess)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItReturnsEternalInfrequentAccessForConversationWithTeam() {
        let moc = coreDataStack.syncContext
        moc.performGroupedBlock {
            // given
            let conversation = ZMConversation.insertNewObject(in: moc)

            // when
            conversation.team = .insertNewObject(in: moc)
            conversation.team?.remoteIdentifier = .init()

            // then
            XCTAssert(conversation.hasTeam)
            XCTAssertEqual(AssetRequestFactory.Retention(conversation: conversation), .eternalInfrequentAccess)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItReturnsEternalInfrequentAccessForAConversationWithAParticipantsWithTeam() {

        // given
        let user = ZMUser.insertNewObject(in: coreDataStack.viewContext)
        user.remoteIdentifier = UUID()
        user.teamIdentifier = .init()

        // when
        guard let conversation = ZMConversation.insertGroupConversation(session: coreDataStack, participants: [user])
        else { return XCTFail("no conversation") }

        // then
        XCTAssert(conversation.containsTeamUser)
        XCTAssertEqual(AssetRequestFactory.Retention(conversation: conversation), .eternalInfrequentAccess)
    }

    // MARK: - Upstream requests

    func test_UpstreamRequest_V0() throws {
        // Given
        let sut = AssetRequestFactory()
        let data = Data([1, 2, 3])
        let apiVersion = APIVersion.v0

        // When
        let request = try XCTUnwrap(sut.upstreamRequestForAsset(
            withData: data,
            retention: .eternal,
            assetAuditLogMetaData: nil,
            apiVersion: apiVersion
        ))

        // Then
        XCTAssertEqual(request.path, "/assets/v3")
    }

    func test_UpstreamRequest_V1() throws {
        // Given
        let sut = AssetRequestFactory()
        let data = Data([1, 2, 3])
        let apiVersion = APIVersion.v1

        // When
        let request = try XCTUnwrap(sut.upstreamRequestForAsset(
            withData: data,
            retention: .eternal,
            assetAuditLogMetaData: nil,
            apiVersion: apiVersion
        ))

        // Then
        XCTAssertEqual(request.path, "/v1/assets/v3")
    }

    func test_UpstreamRequest_V2() throws {
        // Given
        let sut = AssetRequestFactory()
        let data = Data([1, 2, 3])
        let apiVersion = APIVersion.v2

        // When
        let request = try XCTUnwrap(sut.upstreamRequestForAsset(
            withData: data,
            retention: .eternal,
            assetAuditLogMetaData: nil,
            apiVersion: apiVersion
        ))

        // Then
        XCTAssertEqual(request.path, "/v2/assets")
    }

    func test_BackgroundUpstreamRequest_V0() throws {
        try coreDataStack.syncContext.performAndWait {
            // Given
            let sut = AssetRequestFactory()
            let sender = createUser()
            let message = ZMAssetClientMessage(nonce: .create(), managedObjectContext: coreDataStack.syncContext)
            message.sender = sender
            message.visibleInConversation = createGroupConversation(with: sender)

            let data = Data([1, 2, 3])
            let apiVersion = APIVersion.v0

            // When
            let request = try XCTUnwrap(sut.backgroundUpstreamRequestForAsset(
                message: message,
                withData: data,
                retention: .eternal,
                assetAuditLogMetaData: nil,
                apiVersion: apiVersion
            ))

            // Then
            XCTAssertEqual(request.path, "/assets/v3")
        }
    }

    func test_BackgroundUpstreamRequest_V1() throws {
        try coreDataStack.syncContext.performAndWait {
            // Given
            let sut = AssetRequestFactory()
            let sender = createUser()
            let message = ZMAssetClientMessage(nonce: .create(), managedObjectContext: coreDataStack.syncContext)
            message.sender = sender
            message.visibleInConversation = createGroupConversation(with: sender)

            let data = Data([1, 2, 3])
            let apiVersion = APIVersion.v1

            // When
            let request = try XCTUnwrap(sut.backgroundUpstreamRequestForAsset(
                message: message,
                withData: data,
                retention: .eternal,
                assetAuditLogMetaData: nil,
                apiVersion: apiVersion
            ))

            // Then
            XCTAssertEqual(request.path, "/v1/assets/v3")
        }
    }

    func test_BackgroundUpstreamRequest_V2() throws {
        try coreDataStack.syncContext.performAndWait {
            // Given
            let sut = AssetRequestFactory()
            let sender = createUser()
            let message = ZMAssetClientMessage(nonce: .create(), managedObjectContext: coreDataStack.syncContext)
            message.sender = sender
            message.visibleInConversation = createGroupConversation(with: sender)

            let data = Data([1, 2, 3])
            let apiVersion = APIVersion.v2

            // When
            let request = try XCTUnwrap(sut.backgroundUpstreamRequestForAsset(
                message: message,
                withData: data,
                retention: .eternal,
                assetAuditLogMetaData: nil,
                apiVersion: apiVersion
            ))

            // Then
            XCTAssertEqual(request.path, "/v2/assets")
        }
    }

    func test_AssetAuditLogMetaData() throws {
        // Given
        let sut = AssetRequestFactory()
        let data = Data([1, 2, 3])
        let id = UUID()
        let metaData = AssetRequestFactory.AssetAuditLogMetaData(
            conversationID: QualifiedID(uuid: id, domain: "wire.com"),
            fileName: "picture.jpg",
            mimeType: "image/jpeg"
        )

        // When
        let multipartData = try sut.dataForMultipartAssetUploadRequest(
            data,
            shareable: false,
            retention: .eternal,
            assetAuditLogMetaData: metaData
        )

        // Then
        var string = String(decoding: multipartData, as: UTF8.self)

        guard let jsonSubstring = string.firstMatch(of: /{.*}/)?.0 else {
            XCTFail("No JSON object found")
            return
        }

        let jsonString = String(jsonSubstring)
        let jsonData = Data(jsonString.utf8)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        XCTAssertEqual((json["convId"] as? [String: String])?["id"], id.transportString())
        XCTAssertEqual((json["convId"] as? [String: String])?["domain"], "wire.com")
        XCTAssertEqual(json["filetype"] as? String, "image/jpeg")
        XCTAssertEqual(json["filename"] as? String, "picture.jpg")
        XCTAssertEqual(json["retention"] as? String, "eternal")
        XCTAssertEqual(json["public"] as? Bool, false)
    }

}
