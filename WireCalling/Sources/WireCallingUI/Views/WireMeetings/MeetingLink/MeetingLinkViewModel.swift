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
    var isGeneratingLink = false
    var password = ""
    var confirmPassword = ""
    var hasRotationError = false
    private(set) var isCreating = false
    private(set) var didCreateLink = false
    private let fetchLink: @Sendable () async throws -> MeetingLink?
    private let refreshLink: (@Sendable (String?) async throws -> MeetingLink?)?

    init(
        fetchLink: @escaping @Sendable () async throws -> MeetingLink?,
        refreshLink: (@Sendable (String?) async throws -> MeetingLink?)? = nil
    ) {
        self.fetchLink = fetchLink
        self.refreshLink = refreshLink
    }

    var canRotate: Bool { refreshLink != nil }
    var isPasswordValid: Bool { MeetingFormViewModel.isPasswordValid(password) }

    var passwordsMatch: Bool {
        password.unicodeScalars.elementsEqual(confirmPassword.unicodeScalars)
    }

    func beginRotation() {
        password = ""
        confirmPassword = ""
        didCreateLink = false
        hasRotationError = false
        copyConfirmation = nil
        isGeneratingLink = true
    }

    func generatePassword() {
        password = MeetingFormViewModel.makePassword()
        confirmPassword = password
    }

    func copyPassword(isClipboardEnabled: Bool, to pasteboard: UIPasteboard = .general) {
        guard isClipboardEnabled, !isCreating, !didCreateLink, !password.isEmpty, isPasswordValid else { return }
        pasteboard.string = password
    }

    func createLink() async {
        guard let refreshLink, !isCreating, !didCreateLink, isPasswordValid, passwordsMatch else { return }
        isCreating = true
        hasRotationError = false
        defer { isCreating = false }
        do {
            guard let link = try await refreshLink(password.isEmpty ? nil : password) else {
                throw URLError(.badServerResponse)
            }
            password = ""
            confirmPassword = ""
            state = .loaded(link)
            copyConfirmation = nil
            didCreateLink = true
        } catch {
            hasRotationError = true
        }
    }

    func load() async {
        guard !isGeneratingLink else { return }
        state = .loading
        do {
            let link = try await fetchLink()
            guard !Task.isCancelled, !isGeneratingLink else { return }
            state = link.map(State.loaded) ?? .unavailable
        } catch {
            guard !Task.isCancelled, !isGeneratingLink else { return }
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
