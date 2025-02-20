//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public class SwitchBackendConfirmationViewModel {

    private typealias Strings = L10n.SwitchBackendConfirmation

    // MARK: - State

    let items: [ItemUIModel]

    private let action: (Event) -> Void

    // MARK: - Life cycle

    convenience init(
        environment: BackendEnvironmentInfo,
        action: @escaping (Event) -> Void
    ) {
        self.init(
            backendName: environment.title,
            backendURL: environment.backendURL.absoluteString,
            backendWSURL: environment.backendWSURL.absoluteString,
            blacklistURL: environment.blacklistURL.absoluteString,
            teamsURL: environment.teamsURL.absoluteString,
            accountsURL: environment.accountsURL.absoluteString,
            websiteURL: environment.websiteURL.absoluteString,
            action: action
        )
    }

    public init(
        backendName: String,
        backendURL: String,
        backendWSURL: String,
        blacklistURL: String,
        teamsURL: String,
        accountsURL: String,
        websiteURL: String,
        action: @escaping (Event) -> Void
    ) {
        self.action = action
        self.items = [
            ItemUIModel(title: Strings.backendName, value: backendName, isURL: false),
            ItemUIModel(title: Strings.backendUrl, value: backendURL, isURL: true),
            ItemUIModel(title: Strings.backendWsurl, value: backendWSURL, isURL: true),
            ItemUIModel(title: Strings.blacklistUrl, value: blacklistURL, isURL: true),
            ItemUIModel(title: Strings.teamsUrl, value: teamsURL, isURL: true),
            ItemUIModel(title: Strings.accountsUrl, value: accountsURL, isURL: true),
            ItemUIModel(title: Strings.websiteUrl, value: websiteURL, isURL: true)
        ]
    }

    // MARK: - Events

    public enum Event {

        case didCancel
        case didConfirm

    }

    func handleEvent(_ event: Event) {
        action(event)
    }

    // MARK: - Model

    package struct ItemUIModel {
        let title: String
        let value: String
        let isURL: Bool
    }

}
