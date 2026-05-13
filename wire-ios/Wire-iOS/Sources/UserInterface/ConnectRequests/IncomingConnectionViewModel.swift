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

enum IncomingConnectionAction: UInt {
    case ignore
    case accept
}

final class IncomingConnectionViewModel {

    enum State: Equatable {
        case incoming
        case alreadyConnected
    }

    enum ViewEvent {
        case acceptTapped
        case ignoreTapped
    }

    struct DisplayState {
        let user: UserType
        let userSession: UserSession
        let classificationProvider: SecurityClassificationProviding?
    }

    private let userSession: UserSession
    private let user: UserType

    init(userSession: UserSession, user: UserType) {
        self.userSession = userSession
        self.user = user
    }

    var state: State {
        user.isConnected ? .alreadyConnected : .incoming
    }

    var displayState: DisplayState {
        DisplayState(
            user: user,
            userSession: userSession,
            classificationProvider: userSession as? SecurityClassificationProviding
        )
    }

    func refreshDataIfNeeded() {
        guard state == .incoming else { return }

        user.refreshData()
    }

    func action(for event: ViewEvent) -> IncomingConnectionAction {
        switch event {
        case .acceptTapped:
            .accept
        case .ignoreTapped:
            .ignore
        }
    }
}
