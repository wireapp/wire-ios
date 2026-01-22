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

import WireMessagingDomain
import XCTest
@testable import WireMessagingUI

final class ConversationChannelCreationFormViewModelTests: XCTestCase {

    // MARK: - Update Channel Name with Empty String

    func testOnChannelNameUpdate_emptyValue() {
        // Given
        let sut = ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }
        let value = ""

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .failure(.tooShort))
    }

    // MARK: - Update Channel Name with Excessively Long String

    func testOnChannelNameUpdate_longString() {
        // Given
        let sut = ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }
        let value = String(
            repeating: "a",
            count: ConversationChannelCreationFormViewModel.Constants.channelNameMaxStringLength + 1
        )

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .failure(.tooLong))
    }

    // MARK: - Update Channel Name with Excessively Big String

    func testOnChannelNameUpdate_bigString() {
        // Given
        let sut = ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }
        let value = String(
            repeating: "\(0x27BF)",
            count: ConversationChannelCreationFormViewModel.Constants.channelNameMaxByteLength + 1
        )

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .failure(.tooLong))
    }

    // MARK: - Update Channel Name with Whitespace String

    func testOnChannelNameUpdate_whitespaceString() {
        // Given
        let sut = ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }
        let value = String(
            repeating: " ",
            count: ConversationChannelCreationFormViewModel.Constants.channelNameMaxStringLength
        )

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .failure(.tooShort))
    }

    // MARK: - Update Channel Name with Whitespace Surrounded String

    func testOnChannelNameUpdate_whitespaceSurroundedString() {
        // Given
        let sut = ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }
        let value = " " +
            String(
                repeating: "a",
                count: ConversationChannelCreationFormViewModel.Constants.channelNameMaxStringLength
            ) + " "
        let expectedValue = String(
            repeating: "a",
            count: ConversationChannelCreationFormViewModel.Constants.channelNameMaxStringLength
        )

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .success(expectedValue))
    }

    // MARK: - Update Channel Name with Valid String

    func testOnChannelNameUpdate_validString() {
        // Given
        let sut = ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }
        let value = "a"
        let expectedValue = "a"

        // When
        sut.onChannelNameUpdate(value)

        // Then
        XCTAssertEqual(sut.channelName, .success(expectedValue))
    }

    // MARK: - History option

    func testOnHistoryOptionSelected_Returns_Correct_Value() {
        // Given
        let sut = ConversationChannelCreationFormViewModel(
            channelName: "Test",
            isUserPremium: true,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }

        let useCases = [
            ChannelHistoryOption.oneDay,
            .oneWeek,
            .fourWeeks,
            .unlimited,
            .custom
        ]

        for useCase in useCases {
            // When
            sut.channelHistoryOption = useCase
            let channelCreationSettings = sut.getChannelCreationSettings()
            // Then
            switch useCase {
            case .off:
                XCTAssertNil(channelCreationSettings?.historyDepth)
            case .oneDay:
                XCTAssertEqual(channelCreationSettings?.historyDepth, "One day")
            case .oneWeek:
                XCTAssertEqual(channelCreationSettings?.historyDepth, "One week")
            case .fourWeeks:
                XCTAssertEqual(channelCreationSettings?.historyDepth, "Four weeks")
            case .unlimited:
                XCTAssertEqual(channelCreationSettings?.historyDepth, "Unlimited")
            case .custom: // 10 days
                XCTAssertEqual(channelCreationSettings?.historyDepth, "10 days")
            }
        }

    }
}
