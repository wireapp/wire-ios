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

@testable import WireRequestStrategy
import WireRequestStrategySupport
import XCTest

final class FeatureConfigRequestStrategyTests: MessagingTestBase {

    // MARK: - Properties

    var sut: FeatureConfigRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var featureRepository: FeatureRepository!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .slowSyncing

        sut = FeatureConfigRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus,
            syncProgress: MockSyncProgress()
        )

        featureRepository = .init(context: syncMOC)
    }

    override func tearDown() {
        sut = nil
        mockApplicationStatus = nil
        featureRepository = nil
        super.tearDown()
    }

    // MARK: - Processing events

    func test_ItProcessesEvent_AppLock() {
        syncMOC.performGroupedAndWait {
            // Given
            let appLock = Feature.AppLock(
                status: .disabled,
                config: .init(enforceAppLock: false, inactivityTimeoutSecs: 10)
            )

            self.featureRepository.storeAppLock(appLock)

            let data: NSDictionary = [
                "status": "enabled",
                "config": [
                    "enforceAppLock": true,
                    "inactivityTimeoutSecs": 60
                ]
            ]
            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": data,
                "name": "appLock"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait {
            let existingFeature = self.featureRepository.fetchAppLock()
            XCTAssertEqual(existingFeature.status, .enabled)
            XCTAssertEqual(existingFeature.config.enforceAppLock, true)
            XCTAssertEqual(existingFeature.config.inactivityTimeoutSecs, 60)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItProcessesEvent_FileSharing() {
        syncMOC.performGroupedAndWait {
            // Given
            self.featureRepository.storeFileSharing(.init(status: .disabled))

            let data: NSDictionary = [
                "status": "enabled"
            ]
            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": data,
                "name": "fileSharing"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait {
            let existingFeature = self.featureRepository.fetchFileSharing()
            XCTAssertEqual(existingFeature.status, .enabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItProcessesEvent_SelfDeletingMessages() {
        syncMOC.performGroupedAndWait {
            // Given
            let selfDeletingMessages = Feature.SelfDeletingMessages(
                status: .disabled,
                config: .init(enforcedTimeoutSeconds: 0)
            )

            self.featureRepository.storeSelfDeletingMessages(selfDeletingMessages)

            let data: NSDictionary = [
                "status": "enabled",
                "config": [
                    "enforcedTimeoutSeconds": 60
                ]
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": data,
                "name": "selfDeletingMessages"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait {
            let existingfeature = self.featureRepository.fetchSelfDeletingMesssages()
            XCTAssertEqual(existingfeature.status, .enabled)
            XCTAssertEqual(existingfeature.config.enforcedTimeoutSeconds, 60)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItProcessesEvent_ConferenceCalling() {
        syncMOC.performGroupedAndWait {
            // Given
            self.featureRepository.storeConferenceCalling(.init(status: .disabled))

            let dict: NSDictionary = [
                "status": "enabled"
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": dict,
                "name": "conferenceCalling"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait {
            let existingFeature = self.featureRepository.fetchConferenceCalling()
            XCTAssertNotNil(existingFeature)
            XCTAssertEqual(existingFeature.status, .enabled)
        }
    }

    func test_ItProcessesEvent_ConversationGuestLinks() {
        syncMOC.performGroupedAndWait {
            // Given
            self.featureRepository.storeConversationGuestLinks(.init(status: .disabled))

            let dict: NSDictionary = [
                "status": "enabled"
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": dict,
                "name": "conversationGuestLinks"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait {
            let existingFeature = self.featureRepository.fetchConversationGuestLinks()
            XCTAssertNotNil(existingFeature)
            XCTAssertEqual(existingFeature.status, .enabled)
        }
    }

    func test_ItProcessesEvent_DigitalSignature() {
        syncMOC.performGroupedAndWait {
            // Given
            self.featureRepository.storeDigitalSignature(.init(status: .disabled))

            let dict: NSDictionary = [
                "status": "enabled"
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": dict,
                "name": "digitalSignature"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait {
            let existingFeature = self.featureRepository.fetchDigitalSignature()
            XCTAssertNotNil(existingFeature)
            XCTAssertEqual(existingFeature.status, .enabled)
        }
    }

    func test_ItProcessesEvent_ClassifiedDomains() {
        syncMOC.performGroupedAndWait {
            // Given
            let classifiedDomains = Feature.ClassifiedDomains(status: .disabled, config: .init())
            self.featureRepository.storeClassifiedDomains(classifiedDomains)

            let data: NSDictionary = [
                "status": "enabled",
                "config": [
                    "domains": ["a", "b", "c"]
                ]
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": data,
                "name": "classifiedDomains"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait {
            let classifiedDomains = self.featureRepository.fetchClassifiedDomains()
            XCTAssertEqual(classifiedDomains.status, .enabled)
            XCTAssertEqual(classifiedDomains.config.domains, ["a", "b", "c"])
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItProcessesEvent_MLS() throws {
        // Given
        try syncMOC.performAndWait {
            let mls = Feature.MLS(status: .disabled, config: .init())
            self.featureRepository.storeMLS(mls)

            let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: MockJSON.mlsWithDefaultProtocolProteus) as? NSDictionary)
            let event = try XCTUnwrap(ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil))

            // When
            self.sut.processEvents(
                [event],
                liveEvents: false,
                prefetchResult: nil
            )
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait {
            let mls = self.featureRepository.fetchMLS()
            XCTAssertEqual(mls.status, .enabled)
            XCTAssertEqual(mls.config.allowedCipherSuites, [.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519])
            XCTAssertEqual(mls.config.defaultCipherSuite, .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
            XCTAssertEqual(mls.config.defaultProtocol, .proteus)
            XCTAssertEqual(mls.config.protocolToggleUsers, [UUID(transportString: "3B5667D3-F4F9-4BFF-AB34-A6FFE8B93E07")])
            XCTAssertEqual(mls.config.supportedProtocols, [.proteus, .mls, .mixed])
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItProcessesEvent_MLS_defaultProtocolIsMLS() throws {
        // Given
        try syncMOC.performAndWait {
            let mls = Feature.MLS(status: .disabled, config: .init())
            self.featureRepository.storeMLS(mls)

            let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: MockJSON.mlsWithDefaultProtocolMLS) as? NSDictionary)
            let event = try XCTUnwrap(ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil))

            // When
            self.sut.processEvents(
                [event],
                liveEvents: false,
                prefetchResult: nil
            )
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait {
            let mls = self.featureRepository.fetchMLS()
            XCTAssertEqual(mls.status, .enabled)
            XCTAssertEqual(mls.config.allowedCipherSuites, [.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519])
            XCTAssertEqual(mls.config.defaultCipherSuite, .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
            XCTAssertEqual(mls.config.defaultProtocol, .mls)
            XCTAssertEqual(mls.config.protocolToggleUsers, [UUID(transportString: "3B5667D3-F4F9-4BFF-AB34-A6FFE8B93E07")])
            XCTAssertEqual(mls.config.supportedProtocols, [.proteus, .mls, .mixed])
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItProcessesEvent_MLSMigration() {
        // Given
        let startTime = "2023-10-27T12:43:48.000Z"
        let finaliseTime = "2023-11-02T12:43:48.000Z"

        syncMOC.performAndWait {
            let mlsMigration = Feature.MLSMigration(status: .disabled, config: .init())
            self.featureRepository.storeMLSMigration(mlsMigration)

            let config: NSDictionary = [
                "startTime": startTime,
                "finaliseRegardlessAfter": finaliseTime
            ]

            let data: NSDictionary = [
                "status": "enabled",
                "config": config
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": data,
                "name": "mlsMigration"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait {
            let mlsMigration = self.featureRepository.fetchMLSMigration()
            XCTAssertEqual(mlsMigration.status, .enabled)
            XCTAssertEqual(mlsMigration.config.startTime, Date(transportString: startTime))
            XCTAssertEqual(mlsMigration.config.finaliseRegardlessAfter, Date(transportString: finaliseTime))
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}

// MARK: JSON

private enum MockJSON {
    static let mlsWithDefaultProtocolProteus = Data("""
        {
            "type": "feature-config.update",
            "name": "mls",
            "data": {
                "status": "enabled",
                "config": {
                    "allowedCipherSuites": [
                        1
                    ],
                    "defaultCipherSuite": 1,
                    "defaultProtocol": "proteus",
                    "protocolToggleUsers": [
                        "3B5667D3-F4F9-4BFF-AB34-A6FFE8B93E07"
                    ],
                    "supportedProtocols": [
                        "proteus",
                        "mls",
                        "mixed"
                    ]
                }
            }
        }
        """.utf8)

    static let mlsWithDefaultProtocolMLS = Data("""
        {
            "type": "feature-config.update",
            "name": "mls",
            "data": {
                "status": "enabled",
                "config": {
                    "allowedCipherSuites": [
                        1
                    ],
                    "defaultCipherSuite": 1,
                    "defaultProtocol": "mls",
                    "protocolToggleUsers": [
                        "3B5667D3-F4F9-4BFF-AB34-A6FFE8B93E07"
                    ],
                    "supportedProtocols": [
                        "proteus",
                        "mls",
                        "mixed"
                    ]
                }
            }
        }
        """.utf8)
}
