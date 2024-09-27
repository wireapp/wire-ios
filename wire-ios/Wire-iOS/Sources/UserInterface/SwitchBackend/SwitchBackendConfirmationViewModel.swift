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

import Foundation
import SwiftUI
import WireSyncEngine

final class SwitchBackendConfirmationViewModel {
    // MARK: Lifecycle

    convenience init(
        environment: BackendEnvironment,
        didConfirm: @escaping (Bool) -> Void
    ) {
        self.init(
            backendName: environment.title,
            backendURL: environment.backendURL.absoluteString,
            backendWSURL: environment.backendWSURL.absoluteString,
            blacklistURL: environment.blackListURL.absoluteString,
            teamsURL: environment.teamsURL.absoluteString,
            accountsURL: environment.accountsURL.absoluteString,
            websiteURL: environment.websiteURL.absoluteString,
            didConfirm: didConfirm
        )
    }

    init(
        backendName: String,
        backendURL: String,
        backendWSURL: String,
        blacklistURL: String,
        teamsURL: String,
        accountsURL: String,
        websiteURL: String,
        didConfirm: @escaping (Bool) -> Void
    ) {
        self.backendName = backendName
        self.backendURL = backendURL
        self.backendWSURL = backendWSURL
        self.blacklistURL = blacklistURL
        self.teamsURL = teamsURL
        self.accountsURL = accountsURL
        self.websiteURL = websiteURL
        self.didConfirm = didConfirm
    }

    // MARK: Internal

    // MARK: - Events

    enum Event {
        case userDidCancel
        case userDidConfirm
    }

    // MARK: - State

    let backendName: String
    let backendURL: String
    let backendWSURL: String
    let blacklistURL: String
    let teamsURL: String
    let accountsURL: String
    let websiteURL: String

    func handleEvent(_ event: Event) {
        switch event {
        case .userDidCancel:
            didConfirm(false)

        case .userDidConfirm:
            didConfirm(true)
        }
    }

    // MARK: Private

    private let didConfirm: (Bool) -> Void
}
