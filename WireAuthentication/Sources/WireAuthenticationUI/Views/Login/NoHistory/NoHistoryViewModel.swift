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

import Combine
import Foundation
import SwiftUI
import WireAuthenticationAPI

@MainActor
package final class NoHistoryViewModel: ObservableObject {

    package enum Alert: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        case cloudAccountAlreadyRegistered
    }

    // MARK: - View state

    let didReauthenticate: Bool

    @Published var isLoading = false
    @Published var alert: Alert?

    // MARK: - Dependencies

    private let didDetectDomainConflict: Bool
    private let howToChangeEmailURL: URL
    private let howToDeleteAccountURL: URL
    private let onFlowCompletion: () -> Void

    /// Tracks if the user has already acknowledged the alert.
    private var didConfirmAlert = false

    // MARK: - Life cycle

    package init(
        didReauthenticate: Bool,
        didDetectDomainConflict: Bool,
        howToChangeEmailURL: URL,
        howToDeleteAccountURL: URL,
        onFlowCompletion: @escaping () -> Void
    ) {
        self.didReauthenticate = didReauthenticate
        self.didDetectDomainConflict = didDetectDomainConflict
        self.howToChangeEmailURL = howToChangeEmailURL
        self.howToDeleteAccountURL = howToDeleteAccountURL
        self.onFlowCompletion = onFlowCompletion
    }

    // MARK: Actions

    func confirm() {
        onFlowCompletion()

        // For now, the flow will continue outside this module and operations
        // may happen while we still see this view. Show the loading indicator
        // so the user will know something is happening.
        isLoading = true
    }

    func onAppear() {
        if didDetectDomainConflict, !didConfirmAlert {
            alert = .cloudAccountAlreadyRegistered
        }
    }

    func howToChangeEmail() {
        didConfirmAlert = false
        UIApplication.shared.open(howToChangeEmailURL)
    }

    func howToDeleteAccount() {
        didConfirmAlert = false
        UIApplication.shared.open(howToDeleteAccountURL)
    }

    func confirmAlert() {
        didConfirmAlert = true
        alert = nil
    }

}
