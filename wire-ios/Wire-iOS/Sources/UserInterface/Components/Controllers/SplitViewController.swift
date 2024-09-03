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

// TODO: delete file

import UIKit
import WireDesign

extension Notification.Name {
    static let SplitLayoutObservableDidChangeToLayoutSize = Notification.Name("SplitLayoutObservableDidChangeToLayoutSizeNotification")
}

enum SplitViewControllerTransition {
    case `default`
    case present
    case dismiss
}

enum SplitViewControllerLayoutSize {
    case compact
    case regularPortrait
    case regularLandscape
}

protocol SplitLayoutObservable {
    var layoutSize: SplitViewControllerLayoutSize { get }
    var leftViewControllerWidth: CGFloat { get }
}

struct SplitViewControllerObserver: SplitLayoutObservable {

    private(set) weak var splitViewController: UISplitViewController?

    var layoutSize: SplitViewControllerLayoutSize { fatalError() }
    var leftViewControllerWidth: CGFloat { fatalError() }
}
