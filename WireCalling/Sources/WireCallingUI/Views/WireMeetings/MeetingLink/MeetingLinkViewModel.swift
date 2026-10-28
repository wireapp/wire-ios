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
import UIKit
import WireCallingDomain

@Observable
@MainActor
final class MeetingLinkViewModel: Identifiable {

    enum State: Equatable {
        case loading
        case loaded(MeetingLink)
        case unavailable
        case failed
    }

    private(set) var state: State = .loading
    var copyConfirmation: UUID?
    private let fetchLink: @Sendable () async throws -> MeetingLink?

    init(fetchLink: @escaping @Sendable () async throws -> MeetingLink?) {
        self.fetchLink = fetchLink
    }

    func load() async {
        state = .loading
        do {
            let link = try await fetchLink()
            guard !Task.isCancelled else { return }
            state = link.map(State.loaded) ?? .unavailable
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed
        }
    }

    func copyLink(isClipboardEnabled: Bool, to pasteboard: UIPasteboard = .general) {
        guard isClipboardEnabled, case let .loaded(link) = state else { return }
        pasteboard.string = link.url.absoluteString
        copyConfirmation = UUID()
        UIAccessibility.post(notification: .announcement, argument: L10n.Localizable.WireMeetings.Link.copied)
    }
}
