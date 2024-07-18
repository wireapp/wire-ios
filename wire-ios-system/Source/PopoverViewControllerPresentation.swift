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

public enum PopoverViewControllerPresentation {

    case barButtonItem(_ barButtonItem: UIBarButtonItem)
    case sourceView(sourceView: UIView, sourceRect: CGRect)

    public static func sourceView(_ sourceView: UIView, _ sourceRect: CGRect) -> Self {
        .sourceView(sourceView: sourceView, sourceRect: sourceRect)
    }

    public func configure(popoverPresentationController: UIPopoverPresentationController) {
        switch self {

        case .barButtonItem(let barButtonItem):
            popoverPresentationController.barButtonItem = barButtonItem

        case .sourceView(let sourceView, let sourceRect):
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceRect
        }
    }
}
