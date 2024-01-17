//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import XCTest
@testable import WireSyncEngine

final class SupportedProtocolsServiceTests: MessagingTest {

    var featureRepository: MockFeatureRepositoryInterface!
    var userRepository: MockUserRepositoryInterface!
    var sut: SupportedProtocolsService!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()
        featureRepository = MockFeatureRepositoryInterface()
        userRepository = MockUserRepositoryInterface()
        sut = SupportedProtocolsService(
            featureRepository: featureRepository,
            userRepository: userRepository
        )
    }

    override func tearDown() {
        featureRepository = nil
        userRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Mock

    private func mock(allActiveMLSClients: Bool) throws {
        let selfUser = createSelfUser()
        userRepository.selfUser_MockValue = selfUser

        let selfClient = createSelfClient()
        selfClient.lastActiveDate = Date(timeIntervalSinceNow: -.oneDay)
        selfClient.mlsPublicKeys = randomMLSPublicKeys()

        let otherClient = createClient(for: selfUser)
        let validLastActiveDate = Date(timeIntervalSinceNow: -.oneHour)
        let invalidLastActiveDate = Date(timeIntervalSinceNow: -.fourWeeks - .oneHour)
        let validMLSPublicKeys = randomMLSPublicKeys()
        let invalidMLSPublicKeys = UserClient.MLSPublicKeys(ed25519: nil)

        if allActiveMLSClients {
            otherClient.lastActiveDate = validLastActiveDate
            otherClient.mlsPublicKeys = validMLSPublicKeys
        } else {
            // Randomize the fields that make a client not an active mls client.
            otherClient.lastActiveDate = Bool.random() ? validLastActiveDate : invalidLastActiveDate
            otherClient.mlsPublicKeys = Bool.random() ? validMLSPublicKeys : invalidMLSPublicKeys

            // But make sure we do have an invalid client.
            if otherClient.lastActiveDate == validLastActiveDate && otherClient.mlsPublicKeys == validMLSPublicKeys {
                otherClient.lastActiveDate = invalidLastActiveDate
            }
        }
    }

    private func randomMLSPublicKeys() -> UserClient.MLSPublicKeys {
        return UserClient.MLSPublicKeys(ed25519: Data.random().base64EncodedString())
    }

    private func mock(remoteSupportedProtocols: Set<Feature.MLS.Config.MessageProtocol>) {
        featureRepository.fetchMLS_MockValue = .init(
            status: .enabled,
            config: Feature.MLS.Config(supportedProtocols: remoteSupportedProtocols)
        )
    }

    enum MigrationState {

        case disabled
        case notStarted
        case ongoing
        case finalised

    }

    private func mock(migrationState: MigrationState) {
        switch migrationState {
        case .disabled:
            featureRepository.fetchMLSMigration_MockValue = .init(
                status: .disabled,
                config: .init()
            )

        case .notStarted:
            featureRepository.fetchMLSMigration_MockValue = .init(
                status: .enabled,
                config: .init(
                    startTime: Date(timeIntervalSinceNow: .oneDay),
                    finaliseRegardlessAfter: Date(timeIntervalSinceNow: .fourWeeks)
                )
            )

        case .ongoing:
            featureRepository.fetchMLSMigration_MockValue = .init(
                status: .enabled,
                config: .init(
                    startTime: Date(timeIntervalSinceNow: -.oneDay),
                    finaliseRegardlessAfter: Date(timeIntervalSinceNow: .fourWeeks)
                )
            )

        case .finalised:
            featureRepository.fetchMLSMigration_MockValue = .init(
                status: .enabled,
                config: .init(
                    startTime: Date(timeIntervalSinceNow: -.fourWeeks),
                    finaliseRegardlessAfter: Date(timeIntervalSinceNow: -.oneDay)
                )
            )
        }
    }

    // MARK: - Tests

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteProteus() throws {
        try syncMOC.performAndWait {
            // Given
            try mock(allActiveMLSClients: true)
            mock(remoteSupportedProtocols: [.proteus])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])
        }
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteProteusAndMLS() throws {
        try syncMOC.performAndWait {
            // Given
            try mock(allActiveMLSClients: true)
            mock(remoteSupportedProtocols: [.proteus, .mls])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])
        }
    }

    func test_CalculateSupportedProtocols_AllActiveMLSClients_RemoteMLS() throws {
        try syncMOC.performAndWait {
            // Given
            try mock(allActiveMLSClients: true)
            mock(remoteSupportedProtocols: [.mls])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.mls])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.mls])
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteProteus() throws {
        try syncMOC.performAndWait {
            // Given
            try mock(allActiveMLSClients: false)
            mock(remoteSupportedProtocols: [.proteus])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteProteusAndMLS() throws {
        try syncMOC.performAndWait {
            // Given
            try mock(allActiveMLSClients: false)
            mock(remoteSupportedProtocols: [.proteus, .mls])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus, .mls])
        }
    }

    func test_CalculateSupportedProtocols_NotAllActiveMLSClients_RemoteMLS() throws {
        try syncMOC.performAndWait {
            // Given
            try mock(allActiveMLSClients: false)
            mock(remoteSupportedProtocols: [.mls])

            // When / then
            mock(migrationState: .disabled)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.mls])

            mock(migrationState: .notStarted)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .ongoing)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.proteus])

            mock(migrationState: .finalised)
            XCTAssertEqual(sut.calculateSupportedProtocols(), [.mls])
        }
    }

}
