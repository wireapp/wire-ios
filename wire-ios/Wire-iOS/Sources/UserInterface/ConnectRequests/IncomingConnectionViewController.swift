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
import WireSyncEngine

final class IncomingConnectionViewController: UIViewController {

    fileprivate var connectionView: IncomingConnectionView!

    private let viewModel: IncomingConnectionViewModel
    var onAction: ((IncomingConnectionAction) -> Void)?

    init(userSession: UserSession, user: UserType) {
        self.viewModel = IncomingConnectionViewModel(userSession: userSession, user: user)
        super.init(nibName: .none, bundle: .none)

        viewModel.refreshDataIfNeeded()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let displayState = viewModel.displayState

        connectionView = IncomingConnectionView(
            user: displayState.user,
            userSession: displayState.userSession,
            classificationProvider: displayState.classificationProvider
        )
        connectionView.onAccept = { [weak self] _ in
            guard let self else { return }
            onAction?(viewModel.action(for: .acceptTapped))
        }
        connectionView.onIgnore = { [weak self] _ in
            guard let self else { return }
            onAction?(viewModel.action(for: .ignoreTapped))
        }

        view = connectionView
    }

}
