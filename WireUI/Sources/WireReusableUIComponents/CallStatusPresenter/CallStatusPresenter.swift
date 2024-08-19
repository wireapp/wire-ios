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

/// For the provided `mainWindow` argument this class resizes the view of the
/// root view controller's view and displays a view with call status information.
public final class CallStatusPresenter: CallStatusPresenting {

    private(set) weak var mainWindow: UIWindow?
    private var statusView: UIView?

    public init(mainWindow: UIWindow) {
        self.mainWindow = mainWindow
    }

    deinit {
        guard let mainWindow, let statusView else { return }

        Task { @MainActor in
            statusView.removeFromSuperview()
            if let view = mainWindow.rootViewController?.viewIfLoaded {
                view.frame = mainWindow.bounds
            }
        }
    }

    public func updateCallStatus(_ callStatus: CallStatus?) async {
        if statusView == nil { statusView = await UIView() }
        guard let statusView else { return assertionFailure() }

        await MainActor.run { [statusView] in

            print(statusView)

            //
        }
    }
}
