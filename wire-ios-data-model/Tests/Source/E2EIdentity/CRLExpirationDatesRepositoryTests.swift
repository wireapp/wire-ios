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
@testable import WireDataModel
@testable import WireDataModelSupport
import WireFoundation
import XCTest

class CRLExpirationDatesRepositoryTests: XCTestCase {

    // MARK: - Properties

    var sut: CRLExpirationDatesRepository!
    var storage: PrivateUserDefaults<CRLExpirationDatesRepository.Key>!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()

        storage = PrivateUserDefaults<CRLExpirationDatesRepository.Key>(
            userID: .create(),
            storage: .temporary()
        )

        sut = CRLExpirationDatesRepository(storage: storage)
    }

    override func tearDown() {
        sut = nil
        storage = nil
        super.tearDown()
    }

    // MARK: - crlExpirationDateExists

    func test_crlExpirationDateExists_givenDateExists() throws {
        // GIVEN
        let distributionPoint = "dp.example.com"
        let url = try XCTUnwrap(URL(string: distributionPoint))
        storage.set(Date.now, forKey: .expirationDate(dp: distributionPoint))

        // WHEN / THEN
        XCTAssertTrue(sut.crlExpirationDateExists(for: url))
    }

    func test_crlExpirationDateExists_givenDateDoesntExist() throws {
        // GIVEN
        let distributionPoint = "dp.example.com"
        let url = try XCTUnwrap(URL(string: distributionPoint))

        // WHEN / THEN
        XCTAssertFalse(sut.crlExpirationDateExists(for: url))
    }

    // MARK: - storeCRLExpirationDate

    func test_storeCRLExpirationDate() throws {
        // GIVEN
        let distributionPoint = "dp.example.com"
        let url = try XCTUnwrap(URL(string: distributionPoint))
        let date = Date.now

        // WHEN
        sut.storeCRLExpirationDate(date, for: url)

        // THEN
        // date has been stored
        XCTAssertEqual(storage.date(forKey: .expirationDate(dp: distributionPoint)), date)

        // distribution point has been stored
        let storedDistributionPoints = storage.object(forKey: .distributionPoints) as? [String]
        XCTAssertTrue(storedDistributionPoints?.contains(distributionPoint) ?? false)
    }

    func test_storeCRLExpirationDate_MaintainsListOfKnownDistributionPoints() throws {
        // GIVEN
        let dp1 = "dp1.example.com"
        let dp2 = "dp2.example.com"

        let dpUrl1 = try XCTUnwrap(URL(string: dp1))
        let dpUrl2 = try XCTUnwrap(URL(string: dp2))

        // WHEN
        sut.storeCRLExpirationDate(.now, for: dpUrl1)
        sut.storeCRLExpirationDate(.now, for: dpUrl2)
        // storing date for the dp2 twice to assert later that we don't store duplicate distribution points
        sut.storeCRLExpirationDate(.now, for: dpUrl2)

        // THEN
        let storedDistributionPoints = storage.object(forKey: .distributionPoints) as? [String]
        XCTAssertEqual(storedDistributionPoints, [dp1, dp2])
    }

    // MARK: - fetchAllCRLExpirationDates

    func test_fetchAllCRLExpirationDates() throws {
        // GIVEN
        let dp1 = "dp1.example.com"
        let dp2 = "dp2.example.com"

        let dpUrl1 = try XCTUnwrap(URL(string: dp1))
        let dpUrl2 = try XCTUnwrap(URL(string: dp2))

        let now = Date.now
        let distantFuture = Date.distantFuture

        sut.storeCRLExpirationDate(now, for: dpUrl1)
        sut.storeCRLExpirationDate(distantFuture, for: dpUrl2)

        // WHEN
        let expirationDateByURL = sut.fetchAllCRLExpirationDates()

        // THEN
        XCTAssertEqual(expirationDateByURL.count, 2)

        let date1 = expirationDateByURL[dpUrl1]
        XCTAssertNotNil(date1)
        XCTAssertEqual(date1, now)

        let date2 = expirationDateByURL[dpUrl2]
        XCTAssertNotNil(date2)
        XCTAssertEqual(date2, distantFuture)
    }

}
