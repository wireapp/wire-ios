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

extension ZClientViewController: UserObserving {

    public func userDidChange(_ changeInfo: UserChangeInfo) {

        if changeInfo.accentColorValueChanged {
            UIApplication.shared.firstKeyWindow?.tintColor = UIColor.accent()
            backgroundViewController.accentColor = changeInfo.user.accentColor
        }

        if changeInfo.imageMediumDataChanged {

            guard let imageData = changeInfo.user.imageData(for: .complete) else {
                return backgroundViewController.backgroundImage = .none
            }

            Task.detached(priority: .background) { [backgroundViewController] in
                if let image = UIImage(from: imageData, withMaxSize: 40) {
                    let transformer = CoreImageBasedImageTransformer()
                    let backgroundImage = transformer.adjustInputSaturation(value: 2, image: image)
                    await MainActor.run { backgroundViewController.backgroundImage = backgroundImage }
                }
            }
        }
    }

    @objc func setupUserChangeInfoObserver() {
        userObserverToken = userSession.addUserObserver(
            self,
            for: userSession.selfUser
        )
    }
}
