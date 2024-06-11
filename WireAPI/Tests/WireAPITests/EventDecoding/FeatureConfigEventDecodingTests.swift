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

@testable import WireAPI
import XCTest

final class FeatureConfigEventDecodingTests: XCTestCase {
    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = .defaultDecoder
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    func testDecodingFeatureConfigUpdateAppLockEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "FeatureConfigUpdateAppLock")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .featureConfig(.update(Scaffolding.appLockUpdateEvent))
        )
    }

    func testDecodingFeatureConfigUpdateClassfiedDomainsEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "FeatureConfigUpdateClassifiedDomains")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .featureConfig(.update(Scaffolding.classifiedDomainsUpdateEvent))
        )
    }

    func testDecodingFeatureConfigUpdateConferenceCallingEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "FeatureConfigUpdateConferenceCalling")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .featureConfig(.update(Scaffolding.conferenceCallingUpdateEvent))
        )
    }

    func testDecodingFeatureConfigUpdateConversationGuestLinksEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "FeatureConfigUpdateConversationGuestLinks")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .featureConfig(.update(Scaffolding.conversationGuestLinksUpdateEvent))
        )
    }

    func testDecodingFeatureConfigUpdateDigitalSignatureEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "FeatureConfigUpdateDigitalSignature")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .featureConfig(.update(Scaffolding.digitalSignatureUpdateEvent))
        )
    }

    func testDecodingFeatureConfigUpdateEndToEndIdentityEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "FeatureConfigUpdateEndToEndIdentity")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .featureConfig(.update(Scaffolding.endToEndIdentityUpdateEvent))
        )
    }

    func testDecodingFeatureConfigUpdateFileSharingEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "FeatureConfigUpdateFileSharing")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .featureConfig(.update(Scaffolding.fileSharingUpdateEvent))
        )
    }

    func testDecodingFeatureConfigUpdateMLSEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "FeatureConfigUpdateMLS")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .featureConfig(.update(Scaffolding.mlsUpdateEvent))
        )
    }

    func testDecodingFeatureConfigUpdateMLSMigrationEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "FeatureConfigUpdateMLSMigration")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .featureConfig(.update(Scaffolding.mlsMigrationUpdateEvent))
        )
    }

    func testDecodingFeatureConfigUpdateSelfDeletingMessagesEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "FeatureConfigUpdateSelfDeletingMessages")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .featureConfig(.update(Scaffolding.selfDeletingMessagesUpdateEvent))
        )
    }

    private enum Scaffolding {
        static func date(from string: String) -> Date {
            ISO8601DateFormatter.default.date(from: string)!
        }

        static let connectionRemovedEvent = FederationConnectionRemovedEvent(
            domains: [
                "a.com",
                "b.com"
            ]
        )

        static let appLockUpdateEvent = FeatureConfigUpdateEvent(
            featureConfig: .appLock(
                AppLockFeatureConfig(
                    status: .enabled,
                    isMandatory: true,
                    inactivityTimeoutInSeconds: 60
                )
            )
        )

        static let classifiedDomainsUpdateEvent = FeatureConfigUpdateEvent(
            featureConfig: .classifiedDomains(
                ClassifiedDomainsFeatureConfig(
                    status: .enabled,
                    domains: [
                        "a.com",
                        "b.com"
                    ]
                )
            )
        )

        static let conferenceCallingUpdateEvent = FeatureConfigUpdateEvent(
            featureConfig: .conferenceCalling(
                ConferenceCallingFeatureConfig(
                    status: .enabled
                )
            )
        )

        static let conversationGuestLinksUpdateEvent = FeatureConfigUpdateEvent(
            featureConfig: .conversationGuestLinks(
                ConversationGuestLinksFeatureConfig(
                    status: .enabled
                )
            )
        )

        static let digitalSignatureUpdateEvent = FeatureConfigUpdateEvent(
            featureConfig: .digitalSignature(
                DigitalSignatureFeatureConfig(
                    status: .enabled
                )
            )
        )

        static let endToEndIdentityUpdateEvent = FeatureConfigUpdateEvent(
            featureConfig: .endToEndIdentity(
                EndToEndIdentityFeatureConfig(
                    status: .enabled,
                    acmeDiscoveryURL: "www.example.com",
                    verificationExpiration: 123
                )
            )
        )

        static let fileSharingUpdateEvent = FeatureConfigUpdateEvent(
            featureConfig: .fileSharing(
                FileSharingFeatureConfig(
                    status: .enabled
                )
            )
        )

        static let mlsUpdateEvent = FeatureConfigUpdateEvent(
            featureConfig: .mls(
                MLSFeatureConfig(
                    status: .enabled,
                    protocolToggleUsers: [
                        UUID(uuidString: "b8ffd03e-425a-468c-8cfe-1b1c1e1e274c")!,
                        UUID(uuidString: "ef84379d-9bd6-432f-b2d6-ff636343596b")!
                    ],
                    defaultProtocol: .mls,
                    allowedCipherSuites: [
                        .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
                        .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                        .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519
                    ],
                    defaultCipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                    supportedProtocols: [
                        .proteus,
                        .mls
                    ]
                )
            )
        )

        static let mlsMigrationUpdateEvent = FeatureConfigUpdateEvent(
            featureConfig: .mlsMigration(
                MLSMigrationFeatureConfig(
                    status: .enabled,
                    startTime: date(from: "2024-06-04T15:03:07.598Z"),
                    finaliseRegardlessAfter: date(from: "2025-06-04T15:03:07.598Z")
                )
            )
        )

        static let selfDeletingMessagesUpdateEvent = FeatureConfigUpdateEvent(
            featureConfig: .selfDeletingMessages(
                SelfDeletingMessagesFeatureConfig(
                    status: .enabled,
                    enforcedTimeoutSeconds: 123
                )
            )
        )
    }
}
