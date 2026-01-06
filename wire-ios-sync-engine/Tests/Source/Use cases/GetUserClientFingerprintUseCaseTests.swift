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

import Foundation
import WireDataModelSupport
import WireSyncEngineSupport
import WireTesting
import XCTest

@testable import WireSyncEngine

@preconcurrency
final class GetUserClientFingerprintUseCaseTests: MessagingTest {
    var sut: GetUserClientFingerprintUseCase!

    var mockProteusService: MockProteusServiceInterface!
    var mockSessionEstablisher: MockSessionEstablisherInterface!

    let fingerprint = "1234"

    override func setUp() {
        mockProteusService = MockProteusServiceInterface()
        mockSessionEstablisher = MockSessionEstablisherInterface()
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        mockProteusService = nil
        mockSessionEstablisher = nil
        super.tearDown()
    }

    // MARK: - invoke() establishSession

    func test_invoke_ShouldEstablishSession_IfNoSessionEstablished() async {
        await internalTestEstablishSession(sessionEstablished: false)
    }

    func test_invoke_ShouldNotEstablishSession_IfSessionEstablished() async {
        await internalTestEstablishSession(sessionEstablished: true)
    }

    func internalTestEstablishSession(sessionEstablished: Bool) async {
        // GIVEN

        syncMOC.performAndWait {
            syncMOC.proteusService = mockProteusService
        }
        sut = createSut()

        mockProteusService.sessionExistsId_MockValue = sessionEstablished

        let userClient = await syncMOC.perform {
            let userClient = self.createSelfClient()
            userClient.user?.domain = "example.com"
            return userClient
        }

        let expectation = XCTestExpectation(description: "should call establishSession")
        expectation.isInverted = sessionEstablished
        mockSessionEstablisher.establishSessionWithApiVersion_MockMethod = { _, _ in
            expectation.fulfill()
        }

        // WHEN
        let result = await sut.invoke(userClient: userClient)

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertEqual(result, fingerprint.data(using: .utf8))
    }

    // MARK: - fetchRemoteFingerprint

    func test_fetchRemoteFingerprint() async {
        // GIVEN
        sut = createSut()

        let userClient = await syncMOC.perform {
            self.createSelfClient()
        }

        // WHEN
        let result = await sut.fetchRemoteFingerprint(for: userClient)

        // THEN
        XCTAssertEqual(result, fingerprint.data(using: .utf8))
    }

    // MARK: - localFingerprint

    func test_itLoadsLocalFingerprint_ProteusViaCoreCryptoFlagEnabled() async {

        // GIVEN
        sut = createSut()

        await syncMOC.perform {
            _ = self.createSelfClient()
        }

        // WHEN
        guard let result = await sut.localFingerprint() else {
            XCTFail("missing expected data")
            return
        }

        // THEN
        XCTAssertEqual(String(decoding: result, as: UTF8.self), fingerprint)
    }

    // MARK: - Helpers

    private func createSut() -> GetUserClientFingerprintUseCase {

        mockProteusService.localFingerprint_MockMethod = {
            self.fingerprint
        }
        mockProteusService.remoteFingerprintForSession_MockMethod = { _ in
            self.fingerprint
        }

        return GetUserClientFingerprintUseCase(
            proteusService: mockProteusService,
            sessionEstablisher: mockSessionEstablisher,
            managedObjectContext: syncMOC,
            metadata: .mock()
        )
    }

}
