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

extension ConversationContentViewController: ZMNetworkAvailabilityObserver {

    /// Shows the offline notice in the messages while the device is offline, like the network status bar.
    func observeNetworkAvailabilityForOfflineNotice() {
        // The cast is not needed for compilation but is a necessary hack for tests
        guard DeveloperFlag.offlinePendingMessages.isOn, let userSession = userSession as? ZMUserSession else {
            return
        }

        dataSource.showsOfflineNotice = userSession.networkState == .offline
        networkAvailabilityObserverToken = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(
            self,
            notificationContext: userSession.managedObjectContext.notificationContext
        )
    }

    func didChangeAvailability(newState: NetworkState) {
        dataSource.showsOfflineNotice = newState == .offline
    }
}
