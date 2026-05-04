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

import SwiftUI
import WireMessagingUI
import WireTestingPackage
import XCTest

class ConversationChannelIconUIKitTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testColorSchemeVariantsWhenPublic() {
        let sut = ConversationChannelIconUIKit(asset: .gray, isPrivateChannel: false)
        let container = makeContainer(sut: sut)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: container, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: container, named: "dark")
    }

    @MainActor
    func testColorSchemeVariantsWhenPrivate() {
        let sut = ConversationChannelIconUIKit(asset: .gray, isPrivateChannel: true)
        let container = makeContainer(sut: sut)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: container, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: container, named: "dark")
    }

    // MARK: - Private

    @MainActor
    private func makeContainer(sut: UIView) -> UIView {
        let container = UIView()
        container.frame = CGRect(origin: .zero, size: .init(width: 40, height: 40))

        sut.frame.size = .init(width: 28, height: 28)
        sut.center = container.center

        container.addSubview(sut)

        return container
    }

}
