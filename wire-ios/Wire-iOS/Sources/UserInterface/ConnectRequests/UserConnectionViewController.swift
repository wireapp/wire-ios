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
import WireSyncEngine

// MARK: - IncomingConnectionAction

enum IncomingConnectionAction: UInt {
    case ignore, accept
}

// MARK: - IncomingConnectionViewController

final class IncomingConnectionViewController: UIViewController {
    // MARK: Lifecycle

    init(userSession: ZMUserSession?, user: UserType) {
        self.userSession = userSession
        self.user = user
        super.init(nibName: .none, bundle: .none)

        guard !self.user.isConnected else { return }
        user.refreshData()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let userSession: ZMUserSession?
    let user: UserType
    var onAction: ((IncomingConnectionAction) -> Void)?

    override func loadView() {
        connectionView = IncomingConnectionView(user: user)
        connectionView.onAccept = { [weak self] _ in
            guard let self else { return }
            onAction?(.accept)
        }
        connectionView.onIgnore = { [weak self] _ in
            guard let self else { return }
            onAction?(.ignore)
        }

        view = connectionView
    }

    // MARK: Fileprivate

    fileprivate var connectionView: IncomingConnectionView!
}

// MARK: - UserConnectionViewController

final class UserConnectionViewController: UIViewController {
    // MARK: Lifecycle

    init(userSession: ZMUserSession, user: ZMUser) {
        self.userSession = userSession
        self.user = user
        super.init(nibName: .none, bundle: .none)

        guard !self.user.isConnected else { return }
        user.refreshData()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let userSession: ZMUserSession
    let user: ZMUser

    override func loadView() {
        userConnectionView = UserConnectionView(user: user)
        view = userConnectionView
    }

    // MARK: Fileprivate

    fileprivate var userConnectionView: UserConnectionView!
}
