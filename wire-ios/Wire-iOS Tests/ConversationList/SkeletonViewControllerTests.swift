//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import XCTest
import SnapshotTesting
@testable import Wire
import WireTesting

final class SkeletonViewControllerTests: ZMTestCase {
    var sut: SkeletonViewController!
    var mockAccount: Account!

    override func setUp() {
        super.setUp()

        mockAccount = Account.mockAccount(imageData: Data())

        sut = SkeletonViewController(from: mockAccount, to: mockAccount, randomizeDummyItem: false)
    }

    override func tearDown() {
        sut = nil
        mockAccount = nil

        super.tearDown()
    }

    func testForInitState() {
        verify(matching: sut)
    }
}
