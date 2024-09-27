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
import WireSyncEngineSupport
import XCTest

final class E2EIdentityCertificateUpdateStatusUseCaseTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()

        stack = try await CoreDataStackHelper().createStack()
        await stack.syncContext.perform { [self] in
            let conversation = ModelHelper().createSelfMLSConversation(in: stack.syncContext)
            conversation.mlsGroupID = .random()
        }

        mockGetE2eIdentityCertificates = MockGetE2eIdentityCertificatesUseCaseProtocol()

        userDefaults = .temporary()
        userID = UUID.create()
        lastE2EIUpdateDateRepository = LastE2EIdentityUpdateDateRepository(
            userID: userID,
            sharedUserDefaults: userDefaults
        )
        sut = E2EIdentityCertificateUpdateStatusUseCase(
            getE2eIdentityCertificates: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            mlsClientID: .random(),
            context: stack.syncContext,
            lastE2EIUpdateDateRepository: nil
        )
    }

    override func tearDown() async throws {
        stack = nil
        mockGetE2eIdentityCertificates = nil
        userID = nil
        userDefaults = nil
        sut = nil

        try await super.tearDown()
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsBeyondNudgingDate() async throws {
        // Given
        update(certificate: certificate(with: .oneYearFromNow, serverStoragePeriod: .fourWeeks))

        // When
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .noAction)
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInNudgingDate() async throws {
        // Given
        update(certificate: certificate(with: .oneWeek - .oneSecond))

        // When
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .reminder)
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInSevenDaysAndLastAlertWasDisplayedToday() async throws {
        // Given
        lastE2EIUpdateDateRepository.storeLastAlertDate(Date.now)
        sut = E2EIdentityCertificateUpdateStatusUseCase(
            getE2eIdentityCertificates: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            mlsClientID: .random(),
            context: stack.syncContext,
            lastE2EIUpdateDateRepository: lastE2EIUpdateDateRepository
        )
        update(certificate: certificate(with: .oneWeek))

        // When
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .noAction)
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInSevenDaysAndLastAlertWasDisplayedNotToday() async throws {
        // Given
        lastE2EIUpdateDateRepository.storeLastAlertDate(Date.now - .oneDay)
        sut = E2EIdentityCertificateUpdateStatusUseCase(
            getE2eIdentityCertificates: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            mlsClientID: .random(),
            context: stack.syncContext,
            lastE2EIUpdateDateRepository: lastE2EIUpdateDateRepository
        )
        update(certificate: certificate(with: .oneWeek - .oneSecond))

        // When
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .reminder)
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInOneDay() async throws {
        // Given
        update(certificate: certificate(with: .oneDay))
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .reminder)
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInOneDayAndAlertWasShownWithinFourHours() async throws {
        // Given
        lastE2EIUpdateDateRepository.storeLastAlertDate(Date.now)
        sut = E2EIdentityCertificateUpdateStatusUseCase(
            getE2eIdentityCertificates: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            mlsClientID: .random(),
            context: stack.syncContext,
            lastE2EIUpdateDateRepository: lastE2EIUpdateDateRepository
        )
        update(certificate: certificate(with: .oneHour * 4))

        // When
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .noAction)
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInOneDayAndAlertWasShownBeyondFourHours() async throws {
        // Given
        lastE2EIUpdateDateRepository.storeLastAlertDate(Date.now)
        sut = E2EIdentityCertificateUpdateStatusUseCase(
            getE2eIdentityCertificates: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            mlsClientID: .random(),
            context: stack.syncContext,
            lastE2EIUpdateDateRepository: lastE2EIUpdateDateRepository
        )
        update(certificate: certificate(with: .oneHour * 5))

        // When
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .noAction)
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInFourHours() async throws {
        // Given
        update(certificate: certificate(with: .oneHour * 4))
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .reminder)
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInOneHour() async throws {
        // Given
        update(certificate: certificate(with: .oneHour))

        // When
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .reminder)
    }

    func testThatItReturnsBlock_WhenItExpires() async throws {
        update(certificate: certificate(with: 0))
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .block)
    }

    func testThatItReturnsBlock_WhenItIsBeyondExpiryDate() async throws {
        // Given
        update(certificate: certificate(with: -.oneDay))

        // When
        let result = try await sut.invoke()

        // Then
        XCTAssertEqual(result, .block)
    }

    // MARK: Private

    private var mockGetE2eIdentityCertificates: MockGetE2eIdentityCertificatesUseCaseProtocol!
    private var stack: CoreDataStack!
    private var sut: E2EIdentityCertificateUpdateStatusUseCase!
    private var userID: UUID!
    private var userDefaults: UserDefaults!
    private var lastE2EIUpdateDateRepository: LastE2EIdentityUpdateDateRepositoryInterface!

    private func update(certificate: E2eIdentityCertificate) {
        mockGetE2eIdentityCertificates.invokeMlsGroupIdClientIds_MockValue = [certificate]
    }

    private func certificate(
        with expiry: TimeInterval,
        serverStoragePeriod: TimeInterval = 0
    ) -> E2eIdentityCertificate {
        E2eIdentityCertificate(
            clientId: "sdfsdfsdfs",
            certificateDetails: .mockCertificate,
            mlsThumbprint: "ABCDEFGHIJKLMNOPQRSTUVWX",
            notValidBefore: Date.now,
            expiryDate: Date.now + expiry,
            certificateStatus: .valid,
            serialNumber: .mockSerialNumber,
            serverStoragePeriod: serverStoragePeriod,
            randomPeriod: 0
        )
    }
}
