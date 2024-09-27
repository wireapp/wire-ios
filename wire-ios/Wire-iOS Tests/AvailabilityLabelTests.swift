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
import WireDesign
import WireTestingPackage
import XCTest
@testable import Wire

final class AvailabilityLabelTests: XCTestCase {
    // MARK: Internal

    // MARK: - setup

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - List labels

    func testThatItRendersCorrectly_List_NoneAvailability() {
        snapshotHelper.verify(matching: createLabelForList(.none))
    }

    func testThatItRendersCorrectly_List_AvailableAvailability() {
        snapshotHelper.verify(matching: createLabelForList(.available))
    }

    func testThatItRendersCorrectly_List_AvailableAvailabilitySelfUser() {
        snapshotHelper.verify(matching: createLabelForList(.available, appendYouSuffix: true))
    }

    func testThatItRendersCorrectly_List_AwayAvailability() {
        snapshotHelper.verify(matching: createLabelForList(.away))
    }

    func testThatItRendersCorrectly_List_BusyAvailability() {
        snapshotHelper.verify(matching: createLabelForList(.busy))
    }

    // MARK: - Helper Method

    func createLabelForList(
        _ availability: Availability,
        appendYouSuffix: Bool = false
    ) -> UILabel {
        guard let user = ZMUser.selfUser() else { return UILabel() }
        user.availability = availability
        let attributedString = AvailabilityStringBuilder.titleForUser(
            name: user.name ?? "",
            availability: user.availability,
            isE2EICertified: false,
            isProteusVerified: false,
            appendYouSuffix: appendYouSuffix,
            style: .list
        )
        let label = UILabel()
        label.attributedText = attributedString
        label.font = FontSpec(.normal, .regular).font
        label.sizeToFit()
        return label
    }

    // MARK: - Participants labels

    func testThatItRendersCorrectly_Participants_NoneAvailability() {
        snapshotHelper.verify(matching: createLabelForParticipants(.none))
    }

    func testThatItRendersCorrectly_Participants_AvailableAvailability() {
        snapshotHelper.verify(matching: createLabelForParticipants(.available))
    }

    func testThatItRendersCorrectly_Participants_AwayAvailability() {
        snapshotHelper.verify(matching: createLabelForParticipants(.away))
    }

    func testThatItRendersCorrectly_Participants_BusyAvailability() {
        snapshotHelper.verify(matching: createLabelForParticipants(.busy))
    }

    // MARK: - Helper Method

    func createLabelForParticipants(_ availability: Availability) -> UILabel {
        guard let user = ZMUser.selfUser() else { return UILabel() }
        user.availability = availability
        let attributedString = AvailabilityStringBuilder.titleForUser(
            name: user.name ?? "",
            availability: user.availability,
            isE2EICertified: false,
            isProteusVerified: false,
            appendYouSuffix: false,
            style: .participants
        )
        let label = UILabel()
        label.attributedText = attributedString
        label.font = FontSpec(.small, .regular).font
        label.sizeToFit()
        return label
    }

    // MARK: Private

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
}
