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

import XCTest
@testable import Wire

final class ConversationTimeoutOptionsViewModelTests: XCTestCase {

    func testThatItMapsSupportedTimeoutsToSelectableOptions() {
        let sut = ConversationTimeoutOptionsViewModel(currentValue: .fiveMinutes)

        let options = sut.state.options

        XCTAssertEqual(options.map(\.value), MessageDestructionTimeoutValue.all)
        XCTAssertTrue(options.allSatisfy(\.isEnabled))
        XCTAssertEqual(options.filter(\.isSelected).map(\.value), [.fiveMinutes])
    }

    func testThatItAppendsCurrentCustomTimeoutAsDisabledSelectedOption() {
        let customValue = MessageDestructionTimeoutValue.custom(123)
        let sut = ConversationTimeoutOptionsViewModel(currentValue: customValue)

        let options = sut.state.options

        XCTAssertEqual(options.map(\.value), MessageDestructionTimeoutValue.all + [customValue])
        XCTAssertFalse(options.last?.isEnabled ?? true)
        XCTAssertTrue(options.last?.isSelected ?? false)
    }

    func testThatItReturnsTimeoutToSaveOnlyForChangedEnabledOptions() {
        let sut = ConversationTimeoutOptionsViewModel(currentValue: .fiveMinutes)

        XCTAssertNil(sut.timeoutToSave(forOptionAt: 2))
        XCTAssertEqual(sut.timeoutToSave(forOptionAt: 3), .oneHour)
    }

    func testThatItDoesNotReturnTimeoutToSaveForUnsupportedCustomOption() {
        let sut = ConversationTimeoutOptionsViewModel(currentValue: .custom(123))

        XCTAssertNil(sut.timeoutToSave(forOptionAt: MessageDestructionTimeoutValue.all.count))
    }
}
