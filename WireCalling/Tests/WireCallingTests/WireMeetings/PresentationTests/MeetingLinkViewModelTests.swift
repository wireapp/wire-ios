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

    func testCreateLinkSendsNilOrManualPassword() async throws {
        let url = try XCTUnwrap(URL(string: "https://wire.example/meeting-join/?key=key&code=code&domain=wire.example"))
        let recorder = MeetingLinkRefreshRecorder(link: MeetingLink(url: url, hasPassword: false))
        let viewModel = MeetingLinkViewModel(fetchLink: { nil }, refreshLink: { password in
            try await recorder.refresh(password)
        })

        viewModel.beginRotation()
        let pasteboard = UIPasteboard.withUniqueName()
        defer { UIPasteboard.remove(withName: pasteboard.name) }
        pasteboard.string = "unchanged"
        viewModel.generatePassword()
        XCTAssertEqual(viewModel.confirmPassword, viewModel.password)
        viewModel.copyPassword(isClipboardEnabled: false, to: pasteboard)
        XCTAssertEqual(pasteboard.string, "unchanged")
        viewModel.copyPassword(isClipboardEnabled: true, to: pasteboard)
        XCTAssertEqual(pasteboard.string, viewModel.password)
        viewModel.password = ""
        viewModel.confirmPassword = ""

        await viewModel.createLink()
        let passwordsWithoutPassword = await recorder.passwords
        XCTAssertEqual(passwordsWithoutPassword, [nil])

        viewModel.beginRotation()
        viewModel.password = "Abcdef1!"
        viewModel.confirmPassword = "Different1!"
        await viewModel.createLink()
        XCTAssertFalse(viewModel.passwordsMatch)
        let passwordsAfterMismatch = await recorder.passwords
        XCTAssertEqual(passwordsAfterMismatch, [nil])

        viewModel.confirmPassword = viewModel.password
        await viewModel.createLink()
        let passwordsWithManualPassword = await recorder.passwords
        XCTAssertEqual(passwordsWithManualPassword, [nil, "Abcdef1!"])
        XCTAssertTrue(viewModel.didCreateLink)
        XCTAssertEqual(viewModel.state, .loaded(MeetingLink(url: url, hasPassword: false)))
    }

    func testCreateLinkBlocksDuplicateAndCanRetryAfterFailure() async throws {
        let pasteboard = UIPasteboard.withUniqueName()
        defer { UIPasteboard.remove(withName: pasteboard.name) }
        pasteboard.string = "unchanged"
        let url = try XCTUnwrap(
            URL(string: "https://wire.example/meeting-join/?key=key&code=a%2Bb&domain=wire.example")
        )
        let recorder = MeetingLinkRefreshRecorder(link: MeetingLink(url: url, hasPassword: true), failsFirst: true)
        let viewModel = MeetingLinkViewModel(fetchLink: { nil }, refreshLink: { password in
            try await recorder.refresh(password)
        })
        viewModel.beginRotation()
        viewModel.password = "Abcdef1!"
        viewModel.confirmPassword = viewModel.password

        let firstAttempt = Task { await viewModel.createLink() }
        while !(await recorder.hasStartedFirstAttempt) {
            await Task.yield()
        }
        XCTAssertTrue(viewModel.isCreating)
        await viewModel.createLink()
        await recorder.releaseFirstAttempt()
        await firstAttempt.value
        XCTAssertTrue(viewModel.hasRotationError)
        XCTAssertFalse(viewModel.didCreateLink)
        let passwordsAfterFailure = await recorder.passwords
        XCTAssertEqual(passwordsAfterFailure, ["Abcdef1!"])

        await viewModel.createLink()
        XCTAssertFalse(viewModel.hasRotationError)
        XCTAssertTrue(viewModel.didCreateLink)
        XCTAssertFalse(viewModel.isCreating)
        XCTAssertEqual(viewModel.password, "")
        XCTAssertEqual(viewModel.confirmPassword, "")
        XCTAssertEqual(viewModel.state, .loaded(MeetingLink(url: url, hasPassword: true)))

        viewModel.copyLink(isClipboardEnabled: false, to: pasteboard)
        XCTAssertEqual(pasteboard.string, "unchanged")
        viewModel.copyLink(isClipboardEnabled: true, to: pasteboard)
        XCTAssertEqual(pasteboard.string, url.absoluteString)
        let passwordsAfterRetry = await recorder.passwords
        XCTAssertEqual(passwordsAfterRetry, ["Abcdef1!", "Abcdef1!"])
    }

    func testInitialFetchCannotReplaceRotatedLink() async throws {
        let oldLink = MeetingLink(url: try XCTUnwrap(URL(string: "https://wire.example/old")), hasPassword: false)
        let newLink = MeetingLink(url: try XCTUnwrap(URL(string: "https://wire.example/new")), hasPassword: true)
        let recorder = MeetingLinkRefreshRecorder(link: newLink)
        let viewModel = MeetingLinkViewModel(
            fetchLink: { await recorder.fetch() },
            refreshLink: { try await recorder.refresh($0) }
        )
        let fetch = Task { await viewModel.load() }
        while !(await recorder.hasStartedFetch) {
            await Task.yield()
        }
        viewModel.beginRotation()
        await viewModel.createLink()
        await recorder.finishFetch(oldLink)
        await fetch.value

        XCTAssertEqual(viewModel.state, .loaded(newLink))
        await viewModel.load()
        XCTAssertEqual(viewModel.state, .loaded(newLink))
    }
}

private actor MeetingLinkRefreshRecorder {

    private let link: MeetingLink
    private let failsFirst: Bool
    private(set) var passwords: [String?] = []
    private(set) var hasStartedFirstAttempt = false
    private(set) var hasStartedFetch = false
    private var firstAttemptContinuation: CheckedContinuation<Void, Never>?
    private var fetchContinuation: CheckedContinuation<MeetingLink?, Never>?

    init(link: MeetingLink, failsFirst: Bool = false) {
        self.link = link
        self.failsFirst = failsFirst
    }

    func fetch() async -> MeetingLink? {
        await withCheckedContinuation {
            fetchContinuation = $0
            hasStartedFetch = true
        }
    }

    func finishFetch(_ link: MeetingLink) {
        fetchContinuation?.resume(returning: link)
        fetchContinuation = nil
    }

    func refresh(_ password: String?) async throws -> MeetingLink? {
        passwords.append(password)
        let shouldFail = failsFirst && passwords.count == 1
        if passwords.count == 1 {
            hasStartedFirstAttempt = true
        }
        if shouldFail {
            await withCheckedContinuation { continuation in
                firstAttemptContinuation = continuation
            }
            throw URLError(.notConnectedToInternet)
        }
        return link
    }

    func releaseFirstAttempt() {
        firstAttemptContinuation?.resume()
        firstAttemptContinuation = nil
    }
}
