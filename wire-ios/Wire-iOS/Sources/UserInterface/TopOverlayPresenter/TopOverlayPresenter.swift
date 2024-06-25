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

struct TopOverlayPresenter: TopOverlayPresenting {

    var rootViewController: UIViewController

    private var zClientViewController: ZClientViewController? {
        // TODO: try to not use the `firstChild` helper
        guard let zClientViewController = rootViewController.firstChild(ofType: ZClientViewController.self) else {
            assertionFailure("there should be at least one instance of `ZClientViewController`")
            return nil
        }

        return zClientViewController
    }

    func presentTopOverlay(_ viewController: UIViewController, animated: Bool) {
        // TODO: move implementation here if possible
        zClientViewController?.setTopOverlay(to: viewController, animated: animated)
    }

    func dismissTopOverlay(animated: Bool) {
        zClientViewController?.setTopOverlay(to: nil, animated: animated)
    }
}
