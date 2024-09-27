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

// MARK: - ClientListViewControllerDelegate

protocol ClientListViewControllerDelegate: AnyObject {
    func finishedDeleting(_ clientListViewController: ClientListViewController)
}

// MARK: - ClientColorVariantProtocol

protocol ClientColorVariantProtocol {
    var headerFooterViewTextColor: UIColor { get }
    func setColor()
}

extension ClientColorVariantProtocol where Self: UIViewController {
    var headerFooterViewTextColor: UIColor {
        SemanticColors.Label.textSectionFooter
    }

    func setColor() {
        view.backgroundColor = SemanticColors.View.backgroundDefault
    }
}
