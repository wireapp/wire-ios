//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
@testable import WireConversationsUI

final class WireConversationChannelCreationFormViewModelTests: XCTestCase {

    // MARK: - Update Channel Name with Empty String

    func testOnChannelNameUpdate_emptyValue() {
        // Given
        let sut = WireConversationChannelCreationFormViewModel(channelName: "") { _ in }
        let value = ""

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .failure(.tooShort))
    }

    // MARK: - Update Channel Name with Excessively Long String

    func testOnChannelNameUpdate_longString() {
        // Given
        let sut = WireConversationChannelCreationFormViewModel(channelName: "") { _ in }
        let value = String(
            repeating: "a",
            count: WireConversationChannelCreationFormViewModel.Constants.channelNameMaxStringLength + 1
        )

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .failure(.tooLong))
    }

    // MARK: - Update Channel Name with Excessively Big String

    func testOnChannelNameUpdate_bigString() {
        // Given
        let sut = WireConversationChannelCreationFormViewModel(channelName: "") { _ in }
        let value = String(
            repeating: "\(0x27BF)",
            count: WireConversationChannelCreationFormViewModel.Constants.channelNameMaxByteLength + 1
        )

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .failure(.tooLong))
    }

    // MARK: - Update Channel Name with Whitespace String

    func testOnChannelNameUpdate_whitespaceString() {
        // Given
        let sut = WireConversationChannelCreationFormViewModel(channelName: "") { _ in }
        let value = String(
            repeating: " ",
            count: WireConversationChannelCreationFormViewModel.Constants.channelNameMaxStringLength
        )

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .failure(.tooShort))
    }

    // MARK: - Update Channel Name with Whitespace Surrounded String

    func testOnChannelNameUpdate_whitespaceSurroundedString() {
        // Given
        let sut = WireConversationChannelCreationFormViewModel(channelName: "") { _ in }
        let value = " " +
            String(
                repeating: "a",
                count: WireConversationChannelCreationFormViewModel.Constants.channelNameMaxStringLength
            ) + " "
        let expectedValue = String(
            repeating: "a",
            count: WireConversationChannelCreationFormViewModel.Constants.channelNameMaxStringLength
        )

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .success(expectedValue))
    }

    // MARK: - Update Channel Name with Valid String

    func testOnChannelNameUpdate_validString() {
        // Given
        let sut = WireConversationChannelCreationFormViewModel(channelName: "") { _ in }
        let value = "a"
        let expectedValue = "a"

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .success(expectedValue))
    }
}
