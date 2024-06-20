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

extension UINavigationItem {

    @available(*, deprecated, message: "Please use `setDynamicFontLabel(title:)`!")
    func setupNavigationBarTitle(title: String) {
        let titleLabel = DynamicFontLabel(
            text: title,
            fontSpec: .headerSemiboldFont,
            color: SemanticColors.Label.textDefault)
        titleView = titleLabel
    }

    func setDynamicFontLabel(title: String) {
        titleView = DynamicFontLabel(
            text: title,
            style: .h3,
            color: SemanticColors.Label.textDefault
        )
    }
}
