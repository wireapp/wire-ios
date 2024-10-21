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

extension ZClientViewController {

    func showAvailabilityBehaviourChangeAlertIfNeeded() {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        var notify = selfUser.needsToNotifyAvailabilityBehaviourChange
        guard notify.contains(.alert) else { return }
        let availability = selfUser.availability

        mainSplitViewController.present(UIAlertController.availabilityExplanation(availability), animated: true)

        userSession.perform {
            notify.remove(.alert)
            selfUser.needsToNotifyAvailabilityBehaviourChange = notify
        }
    }

}
