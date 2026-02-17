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

import WireAccountImageUI
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class ConversationTitleViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testNoAvatarForGroupConversation() {
        let sut = createSUT(ConversationTitleSource(
            accountImageSource: nil,
            title: "Title Sample",
            subtitle: nil,
            isMLS: false,
            isVerified: false,
            isUnderLegalHold: false
        ))

        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func testInitialsAvatarForOneOnOnesWithSubtitle() {
        let sut = createSUT(ConversationTitleSource(
            accountImageSource: AccountImageSource.text("JS"),
            title: "John snow",
            subtitle: "FEDERATED",
            isMLS: false,
            isVerified: false,
            isUnderLegalHold: false
        ))

        snapshotHelper.verify(matching: sut)
        sut.overrideUserInterfaceStyle = .dark
        snapshotHelper.verify(matching: sut, named: "dark")
    }

    @MainActor
    func testImageAvatarForOneOnOnesWithNoSubtitle() {
        let sut = createSUT(ConversationTitleSource(
            accountImageSource: AccountImageSource.image(.init(systemName: "checkmark.circle.fill")!),
            title: "Willy Wonka",
            subtitle: nil,
            isMLS: false,
            isVerified: false,
            isUnderLegalHold: false
        ))

        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func testWithAllContent() {
        let sut = createSUT(ConversationTitleSource(
            accountImageSource: AccountImageSource.image(.init(systemName: "checkmark.circle.fill")!),
            title: "Wonka",
            subtitle: "FEDERATED",
            isMLS: true,
            isVerified: true,
            isUnderLegalHold: true
        ))

        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    private func createSUT(_ source: ConversationTitleSource) -> ConversationTitleView {
        let sut = ConversationTitleView(
            source: source,
            canAnimate: false
        )

        sut.updateOtherUserAccentColor(.systemGreen)
        sut.updateSelfUserAccentColor(.blue)

        sut.frame = CGRect(x: 0, y: 0, width: 150, height: 44)
        return sut
    }
}
