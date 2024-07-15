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
import WireSyncEngine

final class AccentColorChangeHandler: UserObserving {

    typealias AccentColorChangeHandlerBlock = (_ newColor: UIColor?, _ observer: NSObjectProtocol?) -> Void
    private var handlerBlock: AccentColorChangeHandlerBlock?
    private var observer: NSObjectProtocol?
    private var userObserverToken: NSObjectProtocol?

    static func addObserver(_ observer: NSObjectProtocol?, userSession: UserSession, handlerBlock changeHandler: @escaping AccentColorChangeHandlerBlock) -> Self {
        return self.init(observer: observer, handlerBlock: changeHandler, userSession: userSession)
    }

    init(observer: NSObjectProtocol?, handlerBlock changeHandler: @escaping AccentColorChangeHandlerBlock, userSession: UserSession) {
        handlerBlock = changeHandler
        self.observer = observer

        if let selfUser = SelfUser.provider?.providedSelfUser {
            userObserverToken = userSession.addUserObserver(self, for: selfUser)
        }
    }

    func userDidChange(_ change: UserChangeInfo) {
        if change.accentColorValueChanged {
            handlerBlock?(change.user.accentColor, observer)
        }
    }
}
