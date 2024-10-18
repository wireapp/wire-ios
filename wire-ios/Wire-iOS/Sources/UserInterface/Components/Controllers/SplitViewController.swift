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
import WireDesign
import WireMainNavigationUI

extension Notification.Name {
    static let SplitLayoutObservableDidChangeToLayoutSize = Notification.Name("SplitLayoutObservableDidChangeToLayoutSizeNotification")
}

enum SplitViewControllerLayoutSize {
    case compact
    case regularPortrait
    case regularLandscape
}

protocol SplitLayoutObservable: AnyObject {
    @MainActor
    var layoutSize: SplitViewControllerLayoutSize { get }
    @MainActor
    var leftViewControllerWidth: CGFloat { get }
}

@MainActor
final class SplitLayoutObserver: SplitLayoutObservable {

    let zClientViewController: ZClientViewController

    var layoutSize: SplitViewControllerLayoutSize {
        if zClientViewController.mainCoordinator.mainSplitViewState == .collapsed {
            .compact
        } else if zClientViewController.view.bounds.width > zClientViewController.view.bounds.height {
            .regularLandscape
        } else {
            .regularPortrait
        }
    }

    var leftViewControllerWidth: CGFloat {
        let svc = zClientViewController.mainSplitViewController
        let viewController = svc.conversationListUI ?? svc.archiveUI ?? svc.settingsUI
        let view = viewController?.viewIfLoaded
        return view?.frame.width ?? 0
    }

    init(zClientViewController: ZClientViewController) {
        self.zClientViewController = zClientViewController
    }
}
