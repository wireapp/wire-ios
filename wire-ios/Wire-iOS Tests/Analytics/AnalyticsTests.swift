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

import WireCommonComponents
import WireDataModel
import XCTest

@testable import Wire

final class AnalyticsTests: XCTestCase {

    var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
        SelfUser.provider = coreDataFixture.selfUserProvider
    }

    override func tearDown() {
        coreDataFixture = nil
        super.tearDown()
    }

    func testThatItSetsOptOutAnalyticsToSharedSettings() {
        // GIVEN
        TrackingManager.shared.disableAnalyticsSharing = false
        // THEN
        XCTAssertFalse(ExtensionSettings.shared.disableAnalyticsSharing)
        // WHEN
        TrackingManager.shared.disableAnalyticsSharing = true
        // THEN
        XCTAssert(ExtensionSettings.shared.disableAnalyticsSharing)
    }

    func testThatCountlyIsRestartedIfAnalyticsIdentifierChanges() {
        coreDataFixture.teamTest {
            // Given
            let sut = Analytics(optedOut: false)

            let provider = AnalyticsCountlyProvider(
                countlyInstanceType: MockCountly.self,
                countlyAppKey: "dummy countlyAppKey",
                serverURL: URL(string: "www.wire.com")!
            )!

            sut.provider = provider

            let selfUser = coreDataFixture.selfUser!
            sut.selfUser = selfUser

            XCTAssertEqual(MockCountly.startCount, 1)

            // When
            let changeInfo = UserChangeInfo(object: selfUser)
            changeInfo.changedKeys = [#keyPath(ZMUser.analyticsIdentifier)]
            sut.userDidChange(changeInfo)

            // Then
            XCTAssertEqual(MockCountly.startCount, 2)
        }
    }
}
