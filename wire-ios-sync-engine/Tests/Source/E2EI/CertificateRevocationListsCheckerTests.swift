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

import Foundation
@testable import WireDataModelSupport
@testable import WireRequestStrategySupport
@testable import WireSyncEngine
@testable import WireSyncEngineSupport
import XCTest

final class CertificateRevocationListsCheckerTests: XCTestCase {
    private var coreDataHelper: CoreDataStackHelper!

    private var sut: CertificateRevocationListsChecker!
    private var mockCoreCrypto: MockCoreCryptoProtocol!
    private var mockCRLAPI: MockCertificateRevocationListAPIProtocol!
    private var mockMLSGroupVerification: MockMLSGroupVerificationProtocol!
    private var mockSelfClientCertificateProvider: MockSelfClientCertificateProviderProtocol!
    private var mockCRLExpirationDatesRepository: MockCRLExpirationDatesRepositoryProtocol!
    private var mockFeatureRepository: MockFeatureRepositoryInterface!
    private var mockCoreDataStack: CoreDataStack!

    override func setUp() async throws {
        try await super.setUp()

        mockCoreCrypto = MockCoreCryptoProtocol()
        let safeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        let provider = MockCoreCryptoProviderProtocol()
        provider.coreCrypto_MockValue = safeCoreCrypto

        coreDataHelper = CoreDataStackHelper()
        mockCoreDataStack = try await coreDataHelper.createStack()

        mockCRLAPI = MockCertificateRevocationListAPIProtocol()
        mockMLSGroupVerification = MockMLSGroupVerificationProtocol()
        mockSelfClientCertificateProvider = MockSelfClientCertificateProviderProtocol()
        mockCRLExpirationDatesRepository = MockCRLExpirationDatesRepositoryProtocol()
        mockFeatureRepository = .init()
        mockFeatureRepository.fetchE2EI_MockValue = .init(status: .enabled, config: .init())

        sut = CertificateRevocationListsChecker(
            crlAPI: mockCRLAPI,
            crlExpirationDatesRepository: mockCRLExpirationDatesRepository,
            mlsGroupVerification: mockMLSGroupVerification,
            selfClientCertificateProvider: mockSelfClientCertificateProvider,
            fetchE2EIFeatureConfig: { [weak self] in
                return self?.mockFeatureRepository.fetchE2EI_MockValue?.config
            },
            coreCryptoProvider: provider,
            context: mockCoreDataStack.syncContext
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockCoreCrypto = nil
        mockCRLAPI = nil
        mockMLSGroupVerification = nil
        mockSelfClientCertificateProvider = nil
        mockCRLExpirationDatesRepository = nil
        mockFeatureRepository = nil
        mockCoreDataStack = nil
        try coreDataHelper.cleanupDirectory()
        coreDataHelper = nil
        try await super.tearDown()
    }

    // MARK: - Check New CRLs

    func testCheckNewCRLs_GivenThreeDistributionPoints() async throws {
        // GIVEN
        let dp1 = "dp1.example.com"
        let dp2 = "dp2.example.com"
        let dp3 = "dp3.example.com"

        let distributionPoints = try XCTUnwrap(CRLsDistributionPoints(from: [dp1, dp2, dp3]))

        // mock that we have stored an expiration date for dp1
        // so that we only fetch and register CRLs for dp2 and dp3
        mockCRLExpirationDateExists(for: [dp1])

        // mock the results of CRL registration for dp2 and dp3
        let expirationDate = Date.now
        mockCRLRegistration(with: [
            dp2: (dirty: true, expiration: expirationDate),
            dp3: (dirty: false, expiration: nil)
        ])

        // mock other methods
        mockDummies()

        // WHEN
        await sut.checkNewCRLs(from: distributionPoints)

        // THEN

        // It fetches the CRLs from the distribution points dp2 and dp3
        XCTAssertEqual(mockCRLAPI.getRevocationListFrom_Invocations.count, 2)
        XCTAssertEqual(
            Set(mockCRLAPI.getRevocationListFrom_Invocations.map(\.absoluteString)),
            Set([dp2, dp3])
        )

        // It registers the CRLs with core crypto
        XCTAssertEqual(mockCoreCrypto.e2eiRegisterCrlCrlDpCrlDer_Invocations.count, 2)
        XCTAssertEqual(
            Set(mockCoreCrypto.e2eiRegisterCrlCrlDpCrlDer_Invocations.map(\.crlDp)),
            Set([dp2, dp3])
        )

        // It stores the expiration date for dp2
        XCTAssertEqual(mockCRLExpirationDatesRepository.storeCRLExpirationDateFor_Invocations.count, 1)
        let storeCRLExpirationDateInvocation = try XCTUnwrap(
            mockCRLExpirationDatesRepository.storeCRLExpirationDateFor_Invocations.first
        )
        XCTAssertEqual(storeCRLExpirationDateInvocation.distributionPoint.absoluteString, dp2)
        XCTAssertEqual(
            String(reflecting: storeCRLExpirationDateInvocation.expirationDate),
            String(reflecting: expirationDate)
        )

        // It updates conversations verification statuses once (for dp2)
        XCTAssertEqual(mockMLSGroupVerification.updateAllConversations_Invocations.count, 1)
    }

    func testCheckNewCRLs_GivenNoNewCRLs() async throws {
        // GIVEN
        let dp = "dp.example.com"
        let distributionPoints = try XCTUnwrap(CRLsDistributionPoints(from: [dp]))

        mockCRLExpirationDateExists(for: [dp])

        // WHEN
        await sut.checkNewCRLs(from: distributionPoints)

        // THEN
        // It doesn't fetch any CRL
        XCTAssertTrue(mockCRLAPI.getRevocationListFrom_Invocations.isEmpty)

        // It doesn't register any CRL with core crypto
        XCTAssertTrue(mockCoreCrypto.e2eiRegisterCrlCrlDpCrlDer_Invocations.isEmpty)

        // It desn't store expiration date
        XCTAssertTrue(mockCRLExpirationDatesRepository.storeCRLExpirationDateFor_Invocations.isEmpty)

        // It doesn't update conversations verification statuses
        XCTAssertTrue(mockMLSGroupVerification.updateAllConversations_Invocations.isEmpty)
    }

    // MARK: - Check Expired CRLs

    func testCheckExpiredCRLs_RefetchesExpiredCRLs() async throws {
        // GIVEN
        // set up 1st distribution point with CRL expiring now
        let dp1 = "dp1.example.com"
        let dp1Url = try XCTUnwrap(URL(string: dp1))
        let crl1Expiration = Date.now

        // set up 2nd distribution point with CRL expired more than 10 seconds ago
        let dp2 = "dp2.example.com"
        let dp2Url = try XCTUnwrap(URL(string: dp2))
        let crl2Expiration = try XCTUnwrap(Calendar.current.date(
            byAdding: .second,
            value: -15,
            to: .now
        ))

        // set up 3rd distribution point with CRL expiring in the distant future
        let dp3 = "dp3.example.com"
        let dp3Url = try XCTUnwrap(URL(string: dp3))
        let crl3Expiration = Date.distantFuture

        // mock the expiration dates for each distribution point
        mockCRLExpirationDatesRepository.fetchAllCRLExpirationDates_MockValue = [
            dp1Url: crl1Expiration,
            dp2Url: crl2Expiration,
            dp3Url: crl3Expiration
        ]

        // mock the results of CRL registration
        mockCRLRegistration(with: [
            dp2: (dirty: true, expiration: Date.distantFuture)
        ])

        // mock other methods
        mockDummies()

        // WHEN
        await sut.checkExpiredCRLs()

        // THEN
        // It fetches the expiring CRLs
        XCTAssertEqual(mockCRLAPI.getRevocationListFrom_Invocations.count, 1)
        XCTAssertEqual(
            Set(mockCRLAPI.getRevocationListFrom_Invocations.map(\.absoluteString)),
            Set([dp2])
        )

        // It registers the fetched CRLs with core crypto
        XCTAssertEqual(mockCoreCrypto.e2eiRegisterCrlCrlDpCrlDer_Invocations.count, 1)
        XCTAssertEqual(
            Set(mockCoreCrypto.e2eiRegisterCrlCrlDpCrlDer_Invocations.map(\.crlDp)),
            Set([dp2])
        )

        // It stores the expiration dates for dp2
        XCTAssertEqual(mockCRLExpirationDatesRepository.storeCRLExpirationDateFor_Invocations.count, 1)
        XCTAssertEqual(
            Set(mockCRLExpirationDatesRepository.storeCRLExpirationDateFor_Invocations.map(
                \.distributionPoint.absoluteString
            )),
            Set([dp2])
        )
        XCTAssertEqual(
            mockCRLExpirationDatesRepository.storeCRLExpirationDateFor_Invocations.map({
                String(reflecting: $0.expirationDate)
            }),
            [Date.distantFuture].map({
                String(reflecting: $0)
            })
        )

        // It updates conversations verification statuses for dp1
        XCTAssertEqual(mockMLSGroupVerification.updateAllConversations_Invocations.count, 1)

    }

    // MARK: - Helpers

    private func mockCRLRegistration(with configurations: [String: (dirty: Bool, expiration: Date?)]) {
        // Mock registering the CRL with core crypto and returning the registration
        mockCoreCrypto.e2eiRegisterCrlCrlDpCrlDer_MockMethod = { dp, _ in
            guard let configuration = configurations[dp] else {
                return .init(dirty: false, expiration: nil)
            }

            var expirationTimestamp: UInt64?
            if let expirationDate = configuration.expiration {
                expirationTimestamp = UInt64(expirationDate.timeIntervalSince1970)
            }
            return .init(dirty: configuration.dirty, expiration: expirationTimestamp)
        }
    }

    private func mockDummies() {
        // Mock getting the CRL from distribution point
        mockCRLAPI.getRevocationListFrom_MockMethod = { _ in
            return .random()
        }

        // Mock storing the expiration date
        mockCRLExpirationDatesRepository.storeCRLExpirationDateFor_MockMethod = { _, _ in }

        // Mock updating the conversation verification status
        mockMLSGroupVerification.updateAllConversations_MockMethod = { }

        // Mock getting a certificate for a self client
        mockSelfClientCertificateProvider.getCertificate_MockMethod = { return nil }
    }

    private func mockCRLExpirationDateExists(for distributionPoints: [String]) {
        // Mock wether or not there is an expiraiton date for the CRL associated to a given distribution point
        // If there is no expiration date, the distribution point is considered to be unknown/new
        mockCRLExpirationDatesRepository.crlExpirationDateExistsFor_MockMethod = { distributionPoint in
            return distributionPoints.contains(distributionPoint.absoluteString)
        }
    }

}
