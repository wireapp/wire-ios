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
import WireCommonComponents

/// A helper class that provides the label with Dynamic Type Support
/// by conforming to the DynamicTypeCapable Protocol.
class DynamicFontLabel: UILabel, DynamicTypeCapable {

    // MARK: - Properties

    private let onRedrawFont: () -> UIFont?

    // MARK: - initialization

    init(
        text: String = "",
        style: UIFont.FontStyle = .body,
        color: UIColor
    ) {
        // Not needed when we use a font style.
        onRedrawFont = { return nil }
        super.init(frame: .zero)
        self.text = text
        self.textColor = color
        self.font = .font(for: style)
        self.adjustsFontForContentSizeCategory = true
    }

    @available(*, deprecated, message: "Use `init(text:style:color)` instead")
    init(
        text: String? = nil,
        fontSpec: FontSpec = .normalRegularFont,
        color: UIColor
    ) {
        self.onRedrawFont = { return fontSpec.font }

        super.init(frame: .zero)

        self.text = text
        self.font = fontSpec.font
        self.textColor = color
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods
    func redrawFont() {
        guard let newFont = onRedrawFont() else { return }
        self.font = newFont
    }
}
