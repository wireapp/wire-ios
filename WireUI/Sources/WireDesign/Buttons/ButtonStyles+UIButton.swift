//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireFoundation

public extension UIButton {

    var wireButtonStyle: WireButtonStyle? {
        get { objc_getAssociatedObject(self, &wireButtonStyleKey) as? WireButtonStyle }
        set {
            objc_setAssociatedObject(self, &wireButtonStyleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            setConfiguration(wireButtonStyle)
        }
    }

    private func setConfiguration(_ wireButtonStyle: WireButtonStyle?) {
        guard let wireButtonStyle else {
            return configuration = .none
        }

        var configuration = UIButton.Configuration.filled()
        configuration.buttonSize = .large
        configuration.titleTextAttributesTransformer = .init { attributeContainer in
            var attributeContainer = attributeContainer
            attributeContainer.font = .preferredFont(forTextStyle: .headline)
            return attributeContainer
        }
        switch wireButtonStyle {
        case .primary:
            configuration.baseBackgroundColor = ColorTheme.Buttons.Primary.enabled
        case .secondary:
            configuration.baseBackgroundColor = ColorTheme.Buttons.Secondary.enabled
        case .tertiary:
            configuration.baseBackgroundColor = ColorTheme.Buttons.Tertiary.enabled
        case .link:
            fatalError("not implemented yet")
        }
        self.configuration = configuration
    }
}

@MainActor private var wireButtonStyleKey = 0
