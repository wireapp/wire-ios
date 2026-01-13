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
import SwiftUI

/// Identifies an alert and provides it's title and message.
///
/// An `AlertModel` can be produced by a view model and act as data for a SwiftUI alert.
struct AlertModel: Hashable, Identifiable, Sendable {

    var id: Self { self }

    let title: String
    let message: String
    let actionsButtons: [ActionButton]

    struct ActionButton: Hashable, Identifiable, Sendable {
        var id: Self { self }

        let title: String
        let role: ButtonRole?
        let handler: @Sendable () async -> Void

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
        }

        static func == (lhs: ActionButton, rhs: ActionButton) -> Bool {
            lhs.title == rhs.title
        }
    }

}

// MARK: - Common alerts

extension AlertModel {

    private typealias Error = L10n.Localizable.General.Error

    static let noInternet = AlertModel(
        title: Error.NoInternet.title,
        message: Error.NoInternet.message,
        actionsButtons: [
            ActionButton(title: L10n.Localizable.General.confirm, role: .none, handler: {})
        ]
    )

    static let unknownError = AlertModel(
        title: Error.Unknown.title,
        message: Error.Unknown.message,
        actionsButtons: [
            ActionButton(title: L10n.Localizable.General.confirm, role: .none, handler: {})
        ]
    )

}
