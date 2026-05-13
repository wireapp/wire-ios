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

final class ProxyCredentialsViewModel {

    typealias Strings = L10n.Localizable.ProxyCredentials

    // MARK: - Types

    struct DisplayState: Equatable {
        let title: String
        let caption: String
        let username: String
        let password: String
        let usernamePlaceholder: String
        let passwordPlaceholder: String
        let isSubmitButtonEnabled: Bool
    }

    struct Credentials: Equatable {
        let username: String
        let password: String
    }

    enum Field {
        case username
        case password
    }

    enum ValidationError: Error, Equatable {
        case missingUsername
        case missingPassword
    }

    enum Action: Equatable {
        case submit(Credentials)
        case cancel
        case showError(ValidationError)
    }

    enum Route: Equatable {
        case submit(Credentials)
        case cancel
    }

    // MARK: - Properties

    private let backendURL: URL
    private(set) var username: String
    private(set) var password: String

    // MARK: - Computed Properties

    var displayState: DisplayState {
        DisplayState(
            title: Strings.title,
            caption: Strings.caption(backendURL.absoluteString),
            username: username,
            password: password,
            usernamePlaceholder: Strings.Username.placeholder.capitalized,
            passwordPlaceholder: Strings.Password.placeholder.capitalized,
            isSubmitButtonEnabled: validationError == nil
        )
    }

    private var validationError: ValidationError? {
        if username.isEmpty {
            return .missingUsername
        } else if password.isEmpty {
            return .missingPassword
        } else {
            return nil
        }
    }

    private var credentials: Credentials? {
        guard validationError == nil else { return nil }
        return Credentials(username: username, password: password)
    }

    // MARK: - Initialization

    init(
        backendURL: URL,
        username: String = "",
        password: String = ""
    ) {
        self.backendURL = backendURL
        self.username = username
        self.password = password
    }

    // MARK: - Methods

    @discardableResult
    func update(_ field: Field, text: String) -> DisplayState {
        switch field {
        case .username:
            username = text
        case .password:
            password = text
        }

        return displayState
    }

    func submitButtonTapped() -> Action {
        if let credentials {
            return .submit(credentials)
        } else {
            return .showError(validationError ?? .missingUsername)
        }
    }

    func cancelButtonTapped() -> Action {
        .cancel
    }

    func routeForSubmit() -> Route? {
        credentials.map(Route.submit)
    }

    func routeForCancel() -> Route {
        .cancel
    }

    func actionForError(_ error: ValidationError) -> Action {
        .showError(error)
    }
}

extension AuthenticationProxyCredentialsInput {

    init(_ credentials: ProxyCredentialsViewModel.Credentials) {
        self.init(username: credentials.username, password: credentials.password)
    }
}
