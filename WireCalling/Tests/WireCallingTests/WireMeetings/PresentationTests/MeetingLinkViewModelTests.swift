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

import Foundation
import UIKit
import XCTest

@testable import WireCallingDomain
@testable import WireCallingUI

@MainActor
final class MeetingLinkViewModelTests: XCTestCase {

    func testLoadStates() async throws {
        let url = try XCTUnwrap(URL(string: "https://wire.example/meeting-join/?key=key&code=code&domain=wire.example"))
        for hasPassword in [true, false] {
            let link = MeetingLink(url: url, hasPassword: hasPassword)
            let viewModel = MeetingLinkViewModel { link }
            XCTAssertEqual(viewModel.state, .loading)
            await viewModel.load()
            XCTAssertEqual(viewModel.state, .loaded(link))
        }

        let unavailable = MeetingLinkViewModel { nil }
        await unavailable.load()
        XCTAssertEqual(unavailable.state, .unavailable)

        let failed = MeetingLinkViewModel { throw URLError(.notConnectedToInternet) }
        await failed.load()
        XCTAssertEqual(failed.state, .failed)
    }

    func testCopyRequiresLoadedLinkAndClipboardPermission() async throws {
        let pasteboard = UIPasteboard.withUniqueName()
        defer { UIPasteboard.remove(withName: pasteboard.name) }
        pasteboard.string = "unchanged"
        let url =
            try XCTUnwrap(URL(string: "https://wire.example/meeting-join/?key=key&code=a%2Bb&domain=wire.example"))
        let viewModel = MeetingLinkViewModel { MeetingLink(url: url, hasPassword: true) }

        viewModel.copyLink(isClipboardEnabled: true, to: pasteboard)
        XCTAssertEqual(pasteboard.string, "unchanged")
        XCTAssertNil(viewModel.copyConfirmation)

        await viewModel.load()
        viewModel.copyLink(isClipboardEnabled: false, to: pasteboard)
        XCTAssertEqual(pasteboard.string, "unchanged")
        XCTAssertNil(viewModel.copyConfirmation)

        viewModel.copyLink(isClipboardEnabled: true, to: pasteboard)
        XCTAssertEqual(pasteboard.string, url.absoluteString)
        XCTAssertNotNil(viewModel.copyConfirmation)
    }
}
