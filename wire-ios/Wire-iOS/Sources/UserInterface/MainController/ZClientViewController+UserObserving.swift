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
import WireReusableUIComponents

extension ZClientViewController: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.accentColorValueChanged {
            AppDelegate.shared.mainWindow?.tintColor = UIColor.accent()
        }
        if changeInfo.imageMediumDataChanged || changeInfo.imageSmallProfileDataChanged {
            Task { @MainActor [self] in
                let accountImage = await AccountImage(userSession, account, MiniatureAccountImageFactory())
                sidebarViewController.accountInfo = .init(userSession.selfUser, accountImage)
            }
        }
    }

    @objc func setupUserChangeInfoObserver() {
        userObserverToken = userSession.addUserObserver(self, for: userSession.selfUser)
    }
}
