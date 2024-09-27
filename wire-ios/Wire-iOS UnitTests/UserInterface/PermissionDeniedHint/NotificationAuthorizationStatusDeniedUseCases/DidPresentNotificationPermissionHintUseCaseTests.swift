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

import WireSystemSupport
import WireTesting
import WireUtilitiesSupport
import XCTest
@testable import Wire

final class DidPresentNotificationPermissionHintUseCaseTests: XCTestCase {
    private var mockDateProvider: MockCurrentDateProviding!
    private var userDefaults: UserDefaults!
    private var sut: DidPresentNotificationPermissionHintUseCase<MockCurrentDateProviding>!

    override func setUp() {
        mockDateProvider = .init()
        mockDateProvider.now = .now.addingTimeInterval(-.random(in: 1 ... 10))
        userDefaults = .temporary()
        sut = .init(
            currentDateProvider: mockDateProvider,
            userDefaults: userDefaults
        )
    }

    override func tearDown() {
        sut = nil
    }

    func testDateIsStored() throws {
        // When
        sut.invoke()

        // Then
        let date = try XCTUnwrap(userDefaults.value(for: .lastTimeNotificationPermissionHintWasShown))
        XCTAssertEqual(date, mockDateProvider.now)
    }
}
