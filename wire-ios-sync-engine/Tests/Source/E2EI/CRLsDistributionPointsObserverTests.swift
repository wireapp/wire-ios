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

import Combine
import Foundation
import XCTest
@testable import WireSyncEngine
@testable import WireSyncEngineSupport

class CRLsDistributionPointsObserverTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()

        mockCRLsChecker = MockCertificateRevocationListsChecking()
        sut = CRLsDistributionPointsObserver(cRLsChecker: mockCRLsChecker)
        publisher = PassthroughSubject<CRLsDistributionPoints, Never>()
    }

    override func tearDown() {
        publisher = nil
        sut = nil
        mockCRLsChecker = nil
        super.tearDown()
    }

    func test_itObservesNewCRLsDistributionPoints() throws {
        // GIVEN
        sut.startObservingNewCRLsDistributionPoints(from: publisher.eraseToAnyPublisher())

        let expectation = XCTestExpectation(description: "did check new CRLs")
        mockCRLsChecker.checkNewCRLsFrom_MockMethod = { _ in
            expectation.fulfill()
        }

        // WHEN
        let distributionPoints = try XCTUnwrap(CRLsDistributionPoints(from: ["dp.example.com"]))
        publisher.send(distributionPoints)

        // THEN
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(mockCRLsChecker.checkNewCRLsFrom_Invocations.count, 1)
        XCTAssertEqual(mockCRLsChecker.checkNewCRLsFrom_Invocations.first, distributionPoints)
    }

    // MARK: Private

    private var publisher: PassthroughSubject<CRLsDistributionPoints, Never>!
    private var sut: CRLsDistributionPointsObserver!
    private var mockCRLsChecker: MockCertificateRevocationListsChecking!
}
