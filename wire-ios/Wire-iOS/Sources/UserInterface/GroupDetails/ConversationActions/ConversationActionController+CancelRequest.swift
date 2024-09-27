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

import UIKit
import WireDataModel

// MARK: - CancelConnectionRequestResult

enum CancelConnectionRequestResult {
    case cancelRequest, cancel

    // MARK: Internal

    static var all: [CancelConnectionRequestResult] {
        [.cancelRequest, .cancel]
    }

    var title: String {
        switch self {
        case .cancel: L10n.Localizable.Profile.CancelConnectionRequestDialog.buttonCancel
        case .cancelRequest: L10n.Localizable.Profile.CancelConnectionRequestDialog.buttonYes
        }
    }

    static func message(for user: UserType) -> String {
        L10n.Localizable.Profile.CancelConnectionRequestDialog.message(user.name ?? "")
    }

    static func controller(
        for user: UserType,
        handler: @escaping (CancelConnectionRequestResult) -> Void
    ) -> UIAlertController {
        let title = L10n.Localizable.Profile.CancelConnectionRequestDialog.title
        let controller = UIAlertController(title: title, message: message(for: user), preferredStyle: .alert)
        all.map { $0.action(handler) }.forEach(controller.addAction)
        return controller
    }

    func action(_ handler: @escaping (CancelConnectionRequestResult) -> Void) -> UIAlertAction {
        .init(title: title, style: style) { _ in handler(self) }
    }

    // MARK: Private

    private var style: UIAlertAction.Style {
        guard case .cancel = self else {
            return .cancel
        }
        return .default
    }
}

extension UIAlertController {
    static func cancelConnectionRequest(for user: UserType, completion: @escaping (Bool) -> Void) -> UIAlertController {
        CancelConnectionRequestResult.controller(for: user) { result in
            completion(result == .cancel)
        }
    }
}

extension ConversationActionController {
    func requestCancelConnectionRequestResult(
        for user: UserType,
        handler: @escaping (CancelConnectionRequestResult) -> Void
    ) {
        let controller = CancelConnectionRequestResult.controller(for: user, handler: handler)
        present(controller)
    }

    func handleConnectionRequestResult(_ result: CancelConnectionRequestResult, for conversation: ZMConversation) {
        guard case .cancelRequest = result else {
            return
        }

        conversation.connectedUser?.cancelConnectionRequest(completion: { [weak self] error in
            if let error = error as? LocalizedError {
                self?.presentError(error)
            }
        })
    }
}
