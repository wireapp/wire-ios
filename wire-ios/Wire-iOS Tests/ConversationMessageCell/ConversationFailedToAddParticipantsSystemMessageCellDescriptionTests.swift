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

import WireDataModel
import XCTest

@testable import Wire

final class ConversationFailedToAddParticipantsSystemMessageCellDescriptionTests: XCTestCase {

    private func learnMoreLink(for content: NSAttributedString) -> URL? {
        var foundLink: URL?
        content.enumerateAttribute(.link, in: NSRange(location: 0, length: content.length)) { value, _, _ in
            if let url = value as? URL {
                foundLink = url
            }
        }
        return foundLink
    }

    func testLearnMoreLink_PointsToUnreachableBackendInfo_ForDefaultReason() {
        // GIVEN, WHEN
        let sut = ConversationFailedToAddParticipantsSystemMessageCellDescription(
            failedUsers: [MockUserType.createUser(name: "Bruno")],
            isCollapsed: false,
            reason: .failedToAddParticipants,
            buttonAction: {}
        )

        // THEN
        XCTAssertEqual(learnMoreLink(for: sut.configuration.content), WireURLs.shared.unreachableBackendInfo)
    }

    func testLearnMoreLink_PointsToMLSInfo_ForMissingKeyPackagesReason() {
        // GIVEN, WHEN
        let sut = ConversationFailedToAddParticipantsSystemMessageCellDescription(
            failedUsers: [MockUserType.createUser(name: "Bruno")],
            isCollapsed: false,
            reason: .failedToAddParticipantsMLS,
            buttonAction: {}
        )

        // THEN
        XCTAssertEqual(learnMoreLink(for: sut.configuration.content), WireURLs.shared.mlsInfo)
    }

}
