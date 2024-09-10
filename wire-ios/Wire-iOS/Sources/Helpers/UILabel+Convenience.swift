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
import WireDesign

extension UILabel {
    convenience init(
        key: String? = nil,
        size: FontSize = .normal,
        weight: FontWeight = .regular,
        color: UIColor) {
        self.init(frame: .zero)
        text = key.map { $0.localized }
        font = FontSpec(size, weight).font
        textColor = color
    }

    func configMultipleLineLabel() {
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    static func createMultiLineCenterdLabel() -> UILabel {
        let label = DynamicFontLabel(fontSpec: .largeSemiboldFont, color: SemanticColors.Label.textDefault)
        label.textAlignment = .center
        label.configMultipleLineLabel()

        return label
    }

    // MARK: - passcode label factory

    static func createHintLabel() -> UILabel {
        let label = UILabel()

        label.font = FontSpec.smallRegularFont.font!
        label.textColor = SemanticColors.Label.textDefault

        let leadingMargin = CGFloat.AccessoryTextField.horizonalInset

        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = leadingMargin
        style.headIndent = leadingMargin

        label.attributedText = NSAttributedString(string: L10n.Localizable.Passcode.hintLabel,
                                                  attributes: [NSAttributedString.Key.paragraphStyle: style])
        return label
    }
}
