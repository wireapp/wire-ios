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

import WireSyncEngineSupport
import WireDataModelSupport
import XCTest

final class E2EIdentityCertificateUpdateStatusUseCaseTests: XCTestCase {

    private var mockGetE2eIdentityCertificates: MockGetE2eIdentityCertificatesUseCaseProtocol!
    private var stack: CoreDataStack!
    private var sut: E2EIdentityCertificateUpdateStatusUseCase!

    override func setUp() async throws {
        try await super.setUp()

        stack = try await CoreDataStackHelper().createStack()
        await stack.syncContext.perform { [self] in
            let conversation = ModelHelper().createSelfMLSConversation(in: stack.syncContext)
            conversation.mlsGroupID = .random()
        }

        let mockGracePeriodRepository = MockGracePeriodRepositoryInterface()
        mockGracePeriodRepository.storeGracePeriodEndDate_MockMethod = { _ in }
        mockGetE2eIdentityCertificates = MockGetE2eIdentityCertificatesUseCaseProtocol()

        sut = E2EIdentityCertificateUpdateStatusUseCase(
            getE2eIdentityCertificates: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            mlsClientID: .random(),
            context: stack.syncContext,
            lastAlertDate: nil,
            gracePeriodRepository: mockGracePeriodRepository
        )
    }

    override func tearDown() async throws {
        stack = nil
        mockGetE2eIdentityCertificates = nil
        sut = nil

        try await super.tearDown()
    }

    func update(certificate: E2eIdentityCertificate) {
        mockGetE2eIdentityCertificates.invokeMlsGroupIdClientIds_MockValue = [certificate]
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsBeyondNudgingDate() async throws {
        sut.lastAlertDate = nil
        update(certificate: certificate(with: .oneYearFromNow, serverStoragePeriod: .fourWeeks))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .noAction)
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInNudgingDate() async throws {
        sut.lastAlertDate = nil
        update(certificate: certificate(with: .oneWeek - .oneSecond))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .reminder)
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInSevenDaysAndLastAlertWasDisplayedToday() async throws {
        sut.lastAlertDate = Date.now
        update(certificate: certificate(with: .oneWeek))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .noAction)
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInSevenDaysAndLastAlertWasDisplayedNotToday() async throws {
        sut.lastAlertDate = Date.now - .oneDay
        update(certificate: certificate(with: .oneWeek - .oneSecond))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .reminder)
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInOneDay() async throws {
        sut.lastAlertDate = nil
        update(certificate: certificate(with: .oneDay))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .reminder)
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInOneDayAndAlertWasShownWithinFourHours() async throws {
        sut.lastAlertDate = Date.now
        update(certificate: certificate(with: .oneHour * 4))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .noAction)
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInOneDayAndAlertWasShownBeyondFourHours() async throws {
        sut.lastAlertDate = Date.now
        update(certificate: certificate(with: .oneHour * 5))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .noAction)
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInFourHours() async throws {
        sut.lastAlertDate = nil
        update(certificate: certificate(with: .oneHour * 4))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .reminder)
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInOneHour() async throws {
        sut.lastAlertDate = nil
        update(certificate: certificate(with: .oneHour))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .reminder)
    }

    func testThatItReturnsBlock_WhenItExpires() async throws {
        sut.lastAlertDate = nil
        update(certificate: certificate(with: 0))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .block)
    }

    func testThatItReturnsBlock_WhenItIsBeyondExpiryDate() async throws {
        sut.lastAlertDate = nil
        update(certificate: certificate(with: -.oneDay))
        let result = try await sut.invoke()
        XCTAssertEqual(result, .block)
    }

    private func certificate(with expiry: TimeInterval,
                             serverStoragePeriod: TimeInterval = 0) -> E2eIdentityCertificate {
        let certificate = E2eIdentityCertificate(
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
        return certificate
    }
 }
