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

@testable import WireDataModel
import XCTest

class FeatureRepositoryTests: ZMBaseManagedObjectTest {

    override func setUp() {
        super.setUp()
        deleteFeatureIfNeeded(name: .appLock)
        deleteFeatureIfNeeded(name: .classifiedDomains)
        deleteFeatureIfNeeded(name: .conferenceCalling)
        deleteFeatureIfNeeded(name: .conversationGuestLinks)
        deleteFeatureIfNeeded(name: .digitalSignature)
        deleteFeatureIfNeeded(name: .fileSharing)
        deleteFeatureIfNeeded(name: .mls)
        deleteFeatureIfNeeded(name: .selfDeletingMessages)
        deleteFeatureIfNeeded(name: .e2ei)
    }

    // MARK: - Helpers

    func deleteFeatureIfNeeded(name: Feature.Name) {
        syncMOC.performAndWait {
            if let feature = Feature.fetch(name: name, context: self.syncMOC) {
                self.syncMOC.delete(feature)
            }
        }
    }

    func assertFeatureExists(name: Feature.Name) {
        XCTAssertNotNil(Feature.fetch(name: name, context: self.syncMOC))
    }

    func assertFeatureDoesNotExist(name: Feature.Name) {
        XCTAssertNil(Feature.fetch(name: name, context: self.syncMOC))
    }

    // MARK: - App lock

    func testThatItFetchesAppLock() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            let config = Feature.AppLock.Config(
                enforceAppLock: true,
                inactivityTimeoutSecs: 123
            )

            Feature.updateOrCreate(havingName: .appLock, in: self.syncMOC) { feature in
                feature.status = .enabled
                feature.config = try! JSONEncoder().encode(config)
            }

            // When
            let result = sut.fetchAppLock()

            // Then
            XCTAssertEqual(result.status, .enabled)
            XCTAssertEqual(result.config, config)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesAppLock_ItReturnsADefaultConfigWhenConfigDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            Feature.updateOrCreate(havingName: .appLock, in: self.syncMOC) { feature in
                feature.status = .enabled
                feature.config = nil
            }

            // When
            let result = sut.fetchAppLock()

            // Then
            XCTAssertEqual(result.status, .enabled)
            XCTAssertEqual(result.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesAppLock_ItReturnsADefaultConfigWhenObjectDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            self.assertFeatureDoesNotExist(name: .appLock)

            // When
            let result = sut.fetchAppLock()

            // Then
            XCTAssertEqual(result.status, .enabled)
            XCTAssertEqual(result.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItStoresAppLock() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            let config = Feature.AppLock.Config(
                enforceAppLock: true,
                inactivityTimeoutSecs: 123
            )

            let appLock = Feature.AppLock(
                status: .enabled,
                config: config
            )

            self.assertFeatureDoesNotExist(name: .appLock)

            // When
            sut.storeAppLock(appLock)

            // Then
            guard let feature = Feature.fetch(name: .appLock, context: self.syncMOC) else {
                XCTFail("feature not found")
                return
            }

            guard let configData = feature.config else {
                XCTFail("expected config data")
                return
            }

            guard let featureConfig = configData.decode(as: Feature.AppLock.Config.self) else {
                XCTFail("failed to decode config data")
                return
            }

            XCTAssertEqual(feature.status, .enabled)
            XCTAssertEqual(featureConfig, config)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: - Classified domains

    func testThatItFetchesClassifiedDomains() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            let config = Feature.ClassifiedDomains.Config(
                domains: ["foo"]
            )

            Feature.updateOrCreate(havingName: .classifiedDomains, in: self.syncMOC) { feature in
                feature.status = .enabled
                feature.config = try! JSONEncoder().encode(config)
            }

            // When
            let result = sut.fetchClassifiedDomains()

            // Then
            XCTAssertEqual(result.status, .enabled)
            XCTAssertEqual(result.config, config)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesClassifiedDomains_ItReturnsADefaultConfigWhenConfigDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            Feature.updateOrCreate(havingName: .classifiedDomains, in: self.syncMOC) { feature in
                feature.status = .enabled
                feature.config = nil
            }

            // When
            let result = sut.fetchClassifiedDomains()

            // Then
            XCTAssertEqual(result.status, .disabled)
            XCTAssertEqual(result.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesClassifiedDomains_ItReturnsADefaultConfigWhenObjectDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            self.assertFeatureDoesNotExist(name: .classifiedDomains)

            // When
            let result = sut.fetchClassifiedDomains()

            // Then
            XCTAssertEqual(result.status, .disabled)
            XCTAssertEqual(result.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItStoresClassifiedDomains() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            let config = Feature.ClassifiedDomains.Config(
                domains: ["foo"]
            )

            let classifiedDomains = Feature.ClassifiedDomains(
                status: .enabled,
                config: config
            )

            self.assertFeatureDoesNotExist(name: .classifiedDomains)

            // When
            sut.storeClassifiedDomains(classifiedDomains)

            // Then
            guard let feature = Feature.fetch(name: .classifiedDomains, context: self.syncMOC) else {
                XCTFail("feature not found")
                return
            }

            guard let configData = feature.config else {
                XCTFail("expected config data")
                return
            }

            guard let featureConfig = configData.decode(as: Feature.ClassifiedDomains.Config.self) else {
                XCTFail("failed to decode config data")
                return
            }

            XCTAssertEqual(feature.status, .enabled)
            XCTAssertEqual(featureConfig, config)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: - Conference calling

    func testThatItFetchesConferenceCalling() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            Feature.updateOrCreate(havingName: .conferenceCalling, in: self.syncMOC) { feature in
                feature.status = .disabled
            }

            // When
            let result = sut.fetchConferenceCalling()

            // Then
            XCTAssertEqual(result.status, .disabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesConferenceCalling_ItReturnsADefaultConfigWhenObjectDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            self.assertFeatureDoesNotExist(name: .conferenceCalling)

            // When
            let result = sut.fetchConferenceCalling()

            // Then
            XCTAssertEqual(result.status, .enabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItStoresConferenceCalling() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            let conferenceCalling = Feature.ConferenceCalling(status: .disabled)
            self.assertFeatureDoesNotExist(name: .conferenceCalling)

            // When
            sut.storeConferenceCalling(conferenceCalling)

            // Then
            guard let feature = Feature.fetch(name: .conferenceCalling, context: self.syncMOC) else {
                XCTFail("feature not found")
                return
            }

            XCTAssertEqual(feature.status, .disabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItStoresConferenceCalling_V6() async {
        await syncMOC.perform {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            let config = Feature.ConferenceCalling.Config(
                useSFTForOneToOneCalls: true
            )
            let conferenceCalling = Feature.ConferenceCalling(status: .disabled, config: config)
            self.assertFeatureDoesNotExist(name: .conferenceCalling)

            // When
            sut.storeConferenceCalling(conferenceCalling)

            // Then
            guard let feature = Feature.fetch(name: .conferenceCalling, context: self.syncMOC) else {
                XCTFail("feature not found")
                return
            }

            guard let configData = feature.config else {
                XCTFail("expected config data")
                return
            }

            guard let featureConfig = configData.decode(as: Feature.ConferenceCalling.Config.self) else {
                XCTFail("failed to decode config data")
                return
            }

            XCTAssertEqual(feature.status, .disabled)
            XCTAssertEqual(featureConfig, config)
        }
    }

    // MARK: - Conversation guest links

    func testThatItFetchesConversationGuestLinks() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            Feature.updateOrCreate(havingName: .conversationGuestLinks, in: self.syncMOC) { feature in
                feature.status = .disabled
            }

            // When
            let result = sut.fetchConversationGuestLinks()

            // Then
            XCTAssertEqual(result.status, .disabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesConversationGuestLinks_ItReturnsADefaultConfigWhenObjectDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            self.assertFeatureDoesNotExist(name: .conversationGuestLinks)

            // When
            let result = sut.fetchConferenceCalling()

            // Then
            XCTAssertEqual(result.status, .enabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItStoresConversationGuestLinks() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            let conversationGuestLinks = Feature.ConversationGuestLinks(status: .disabled)
            self.assertFeatureDoesNotExist(name: .conversationGuestLinks)

            // When
            sut.storeConversationGuestLinks(conversationGuestLinks)

            // Then
            guard let feature = Feature.fetch(name: .conversationGuestLinks, context: self.syncMOC) else {
                XCTFail("feature not found")
                return
            }

            XCTAssertEqual(feature.status, .disabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: - Digital signature

    func testThatItFetchesDigitalSignature() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            Feature.updateOrCreate(havingName: .digitalSignature, in: self.syncMOC) { feature in
                feature.status = .enabled
            }

            // When
            let result = sut.fetchDigitalSignature()

            // Then
            XCTAssertEqual(result.status, .enabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesDigitalSignature_ItReturnsADefaultConfigWhenObjectDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            self.assertFeatureDoesNotExist(name: .digitalSignature)

            // When
            let result = sut.fetchDigitalSignature()

            // Then
            XCTAssertEqual(result.status, .disabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItStoresDigitalSignature() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            let digitalSignature = Feature.DigitalSignature(status: .enabled)
            self.assertFeatureDoesNotExist(name: .digitalSignature)

            // When
            sut.storeDigitalSignature(digitalSignature)

            // Then
            guard let feature = Feature.fetch(name: .digitalSignature, context: self.syncMOC) else {
                XCTFail("feature not found")
                return
            }

            XCTAssertEqual(feature.status, .enabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: - File sharing

    func testThatItFetchesFileSharing() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            Feature.updateOrCreate(havingName: .fileSharing, in: self.syncMOC) { feature in
                feature.status = .disabled
            }

            // When
            let result = sut.fetchFileSharing()

            // Then
            XCTAssertEqual(result.status, .disabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesFileSharing_ItReturnsADefaultConfigWhenObjectDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            self.assertFeatureDoesNotExist(name: .fileSharing)

            // When
            let result = sut.fetchFileSharing()

            // Then
            XCTAssertEqual(result.status, .enabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItStoresFilesharing() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            let fileSharing = Feature.FileSharing(status: .disabled)
            self.assertFeatureDoesNotExist(name: .fileSharing)

            // When
            sut.storeFileSharing(fileSharing)

            // Then
            guard let feature = Feature.fetch(name: .fileSharing, context: self.syncMOC) else {
                XCTFail("feature not found")
                return
            }

            XCTAssertEqual(feature.status, .disabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: - MLS

    func testThatItFetchesMLS() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            let config = Feature.MLS.Config(
                protocolToggleUsers: [.create()],
                defaultProtocol: .mls,
                allowedCipherSuites: [.MLS_128_DHKEMP256_AES128GCM_SHA256_P256],
                defaultCipherSuite: .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448,
                supportedProtocols: [.mls, .proteus]
            )

            Feature.updateOrCreate(havingName: .mls, in: self.syncMOC) { feature in
                feature.status = .enabled
                feature.config = try! JSONEncoder().encode(config)
            }

            // When
            let result = sut.fetchMLS()

            // Then
            XCTAssertEqual(result.status, .enabled)
            XCTAssertEqual(result.config, config)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesMLSAsync() async {
        // Given
        let context = syncMOC
        let sut = FeatureRepository(context: context)

        let config = Feature.MLS.Config(
            protocolToggleUsers: [.create()],
            defaultProtocol: .mls,
            allowedCipherSuites: [.MLS_128_DHKEMP256_AES128GCM_SHA256_P256],
            defaultCipherSuite: .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448,
            supportedProtocols: [
                .mls,
                .proteus
            ]
        )

        await context.perform {
            Feature.updateOrCreate(havingName: .mls, in: context) { feature in
                feature.status = .enabled
                feature.config = try! JSONEncoder().encode(config)
            }
        }

        // When
        let result = await sut.fetchMLS()

        // Then
        XCTAssertEqual(result.status, .enabled)
        XCTAssertEqual(result.config, config)
    }

    func testThatItFetchesMLS_ItReturnsADefaultConfigWhenConfigDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            Feature.updateOrCreate(havingName: .mls, in: self.syncMOC) { feature in
                feature.status = .enabled
                feature.config = nil
            }

            // When
            let result = sut.fetchMLS()

            // Then
            XCTAssertEqual(result.status, .disabled)
            XCTAssertEqual(result.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesMLS_ItReturnsADefaultConfigWhenObjectDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            self.assertFeatureDoesNotExist(name: .mls)

            // When
            let result = sut.fetchMLS()

            // Then
            XCTAssertEqual(result.status, .disabled)
            XCTAssertEqual(result.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItStoresMLS() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            let config = Feature.MLS.Config(
                protocolToggleUsers: [.create()],
                defaultProtocol: .mls,
                allowedCipherSuites: [.MLS_128_DHKEMP256_AES128GCM_SHA256_P256],
                defaultCipherSuite: .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448,
                supportedProtocols: [.mls, .proteus]
            )

            let mls = Feature.MLS(
                status: .enabled,
                config: config
            )

            self.assertFeatureDoesNotExist(name: .mls)

            // When
            sut.storeMLS(mls)

            // Then
            guard let feature = Feature.fetch(name: .mls, context: self.syncMOC) else {
                XCTFail("feature not found")
                return
            }

            guard let configData = feature.config else {
                XCTFail("expected config data")
                return
            }

            guard let featureConfig = configData.decode(as: Feature.MLS.Config.self) else {
                XCTFail("failed to decode config data")
                return
            }

            XCTAssertEqual(feature.status, .enabled)
            XCTAssertEqual(featureConfig, config)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: - SelfDeletingMessages

    func testThatItFetchesSelfDeletingMessages() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            let config = Feature.SelfDeletingMessages.Config(enforcedTimeoutSeconds: 123)

            Feature.updateOrCreate(havingName: .selfDeletingMessages, in: self.syncMOC) { feature in
                feature.status = .disabled
                feature.config = try! JSONEncoder().encode(config)
            }

            // When
            let result = sut.fetchSelfDeletingMesssages()

            // Then
            XCTAssertEqual(result.status, .disabled)
            XCTAssertEqual(result.config, config)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesSelfDeletingMessages_ItReturnsADefaultConfigWhenConfigDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            Feature.updateOrCreate(havingName: .selfDeletingMessages, in: self.syncMOC) { feature in
                feature.status = .disabled
                feature.config = nil
            }

            // When
            let result = sut.fetchSelfDeletingMesssages()

            // Then
            XCTAssertEqual(result.status, .enabled)
            XCTAssertEqual(result.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesSelfDeletingMessages_ItReturnsADefaultConfigWhenObjectDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            self.assertFeatureDoesNotExist(name: .selfDeletingMessages)

            // When
            let result = sut.fetchSelfDeletingMesssages()

            // Then
            XCTAssertEqual(result.status, .enabled)
            XCTAssertEqual(result.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItStoresSelfDeletingMessages() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            let config = Feature.SelfDeletingMessages.Config(enforcedTimeoutSeconds: 123)

            let selfDeletingMessages = Feature.SelfDeletingMessages(
                status: .disabled,
                config: config
            )

            self.assertFeatureDoesNotExist(name: .selfDeletingMessages)

            // When
            sut.storeSelfDeletingMessages(selfDeletingMessages)

            // Then
            guard let feature = Feature.fetch(name: .selfDeletingMessages, context: self.syncMOC) else {
                XCTFail("feature not found")
                return
            }

            guard let configData = feature.config else {
                XCTFail("expected config data")
                return
            }

            guard let featureConfig = configData.decode(as: Feature.SelfDeletingMessages.Config.self) else {
                XCTFail("failed to decode config data")
                return
            }

            XCTAssertEqual(feature.status, .disabled)
            XCTAssertEqual(featureConfig, config)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: - End-to-end Identity

    func testThatItFetchesE2eI() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            let config = Feature.E2EI.Config(
                acmeDiscoveryUrl: "http://acme",
                verificationExpiration: 12345,
                crlProxy: "http://example",
                useProxyOnMobile: true)

            Feature.updateOrCreate(havingName: .e2ei, in: self.syncMOC) { feature in
                feature.status = .disabled
                feature.config = try! JSONEncoder().encode(config)
            }

            // When
            let result = sut.fetchE2EI()

            // Then
            XCTAssertEqual(result.status, .disabled)
            XCTAssertEqual(result.config, config)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesE2eI_ItReturnsADefaultConfigWhenConfigDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            Feature.updateOrCreate(havingName: .e2ei, in: self.syncMOC) { feature in
                feature.status = .disabled
                feature.config = nil
            }

            // When
            let result = sut.fetchE2EI()

            // Then
            XCTAssertEqual(result.status, .disabled)
            XCTAssertEqual(result.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItFetchesE2eI_ItReturnsADefaultConfigWhenObjectDoesNotExist() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            self.assertFeatureDoesNotExist(name: .e2ei)

            // When
            let result = sut.fetchE2EI()

            // Then
            XCTAssertEqual(result.status, .disabled)
            XCTAssertEqual(result.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItStoresE2eI() {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)

            let config = Feature.E2EI.Config(
                acmeDiscoveryUrl: "http://acme",
                verificationExpiration: 12345)

            let e2ei = Feature.E2EI(
                status: .enabled,
                config: config
            )

            self.assertFeatureDoesNotExist(name: .e2ei)

            // When
            sut.storeE2EI(e2ei)

            // Then
            guard let feature = Feature.fetch(name: .e2ei, context: self.syncMOC) else {
                XCTFail("feature not found")
                return
            }

            guard let configData = feature.config else {
                XCTFail("expected config data")
                return
            }

            guard let featureConfig = configData.decode(as: Feature.E2EI.Config.self) else {
                XCTFail("failed to decode config data")
                return
            }

            XCTAssertEqual(feature.status, .enabled)
            XCTAssertEqual(featureConfig, config)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: - Other

    func testItCreatesDefaultInstances() throws {
        syncMOC.performGroupedBlock {
            // Given
            let sut = FeatureRepository(context: self.syncMOC)
            self.assertFeatureDoesNotExist(name: .appLock)
            self.assertFeatureDoesNotExist(name: .appLock)
            self.assertFeatureDoesNotExist(name: .classifiedDomains)
            self.assertFeatureDoesNotExist(name: .conferenceCalling)
            self.assertFeatureDoesNotExist(name: .conversationGuestLinks)
            self.assertFeatureDoesNotExist(name: .digitalSignature)
            self.assertFeatureDoesNotExist(name: .fileSharing)
            self.assertFeatureDoesNotExist(name: .mls)
            self.assertFeatureDoesNotExist(name: .selfDeletingMessages)
            self.assertFeatureDoesNotExist(name: .e2ei)

            // When
            sut.createDefaultConfigsIfNeeded()

            // Then
            self.assertFeatureExists(name: .appLock)
            self.assertFeatureExists(name: .appLock)
            self.assertFeatureExists(name: .classifiedDomains)
            self.assertFeatureExists(name: .conferenceCalling)
            self.assertFeatureExists(name: .conversationGuestLinks)
            self.assertFeatureExists(name: .digitalSignature)
            self.assertFeatureExists(name: .fileSharing)
            self.assertFeatureExists(name: .mls)
            self.assertFeatureExists(name: .selfDeletingMessages)
            self.assertFeatureExists(name: .e2ei)

        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

}

private extension Data {

    func decode<T: Decodable>(as type: T.Type) -> T? {
        return try? JSONDecoder().decode(type, from: self)
    }

}
