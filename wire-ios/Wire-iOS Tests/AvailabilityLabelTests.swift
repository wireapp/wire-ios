//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireCommonComponents
@testable import Wire

final class AvailabilityLabelTests: BaseSnapshotTestCase {

    // MARK: - List labels

    func testThatItRendersCorrectly_List_NoneAvailability() {
        verify(matching: createLabelForList(.none))
    }

    func testThatItRendersCorrectly_List_AvailableAvailability() {
        verify(matching: createLabelForList(.available))
    }

    func testThatItRendersCorrectly_List_AwayAvailability() {
        verify(matching: createLabelForList(.away))
    }

    func testThatItRendersCorrectly_List_BusyAvailability() {
        verify(matching: createLabelForList(.busy))
    }

    // MARK: - Helper Method

    func createLabelForList(_ availability: Availability) -> UILabel {
        guard let user = ZMUser.selfUser() else { return UILabel() }
        user.availability = availability
        let attributedString = AvailabilityStringBuilder.titleForUser(name: user.name ?? "", availability: user.availability, style: .list)
        let label = UILabel()
        label.attributedText = attributedString
        label.font = FontSpec(.normal, .regular).font
        label.sizeToFit()
        return label
    }

    // MARK: - Participants labels

    func testThatItRendersCorrectly_Participants_NoneAvailability() {
        verify(matching: createLabelForParticipants(.none))
    }

    func testThatItRendersCorrectly_Participants_AvailableAvailability() {
        verify(matching: createLabelForParticipants(.available))
    }

    func testThatItRendersCorrectly_Participants_AwayAvailability() {
        verify(matching: createLabelForParticipants(.away))
    }

    func testThatItRendersCorrectly_Participants_BusyAvailability() {
        verify(matching: createLabelForParticipants(.busy))
    }

    // MARK: - Helper Method

    func createLabelForParticipants(_ availability: Availability) -> UILabel {
        guard let user = ZMUser.selfUser() else { return UILabel() }
        user.availability = availability
        let attributedString = AvailabilityStringBuilder.titleForUser(name: user.name ?? "", availability: user.availability, style: .participants)
        let label = UILabel()
        label.attributedText = attributedString
        label.font = FontSpec(.small, .regular).font
        label.sizeToFit()
        return label
    }
}
