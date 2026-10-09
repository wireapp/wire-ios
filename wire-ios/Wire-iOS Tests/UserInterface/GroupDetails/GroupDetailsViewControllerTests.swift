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

import WireTestingPackage
import XCTest
@testable import Wire

final class GroupDetailsFooterViewTests: XCTestCase, CoreDataFixtureTestHelper {

    var sut: GroupDetailsFooterView!
    var coreDataFixture: CoreDataFixture!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() async throws {
        try await super.setUp()
        coreDataFixture = try await CoreDataFixture()
        SelfUser.provider = coreDataFixture.selfUserProvider
        snapshotHelper = SnapshotHelper().withUserInterfaceStyle(.light)
    }

    override func tearDown() {
        sut = nil
        snapshotHelper = nil
        coreDataFixture = nil
        SelfUser.provider = nil
        super.tearDown()
    }

    func testForAllPhoneWidths() {
        teamTest {
            verifyFooterInAllPhoneWidths()
        }
    }

    func testForPartnerRoleWithNoAddParticipantsButton() {
        teamTest {
            let groupConversation = createGroupConversation()
            groupConversation.teamRemoteIdentifier = team?.remoteIdentifier
            selfUser.membership?.setTeamRole(.partner)
            verifyFooterInAllPhoneWidths { footer in
                footer.update(for: groupConversation, user: selfUser)
            }
        }
    }

    private func verifyFooterInAllPhoneWidths(
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        configure: (GroupDetailsFooterView) -> Void = { _ in }
    ) {
        for width in phoneWidths().sorted() {
            sut = GroupDetailsFooterView()
            sut.frame = CGRect(x: 0, y: 0, width: width, height: 56)
            configure(sut)

            snapshotHelper.verify(
                matching: sut,
                named: "\(width)",
                file: file,
                testName: testName,
                line: line
            )
        }
    }
}
