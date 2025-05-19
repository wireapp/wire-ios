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

import Down
import UIKit
import WireDesign

// MARK: - DownStyle Presets

public extension DownStyle {
    /// The style used within the conversation system message cells.
    static var systemMessage: DownStyle = {
        let style = DownStyle()
        if let fontFromFontSpec = FontSpec(.medium, .none).font {
            style.baseFont = fontFromFontSpec
        }
        style.baseFontColor = SemanticColors.Label.textDefault
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.codeColor = SemanticColors.Label.textDefault
        style.baseParagraphStyle = ParagraphStyleDescriptor.paragraphSpacing(CGFloat.MessageCell.paragraphSpacing).style
        style.listItemPrefixSpacing = 8
        style.renderOnlyValidLinks = false
        return style
    }()

    /// The style used within the conversation message cells.
    static var normal: DownStyle = {
        let style = DownStyle()
        style.baseFont = FontSpec.normalLightFont.font!
        style.baseFontColor = SemanticColors.Label.textDefault
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.codeColor = SemanticColors.Label.textDefault
        style.baseParagraphStyle = NSParagraphStyle.default
        style.listItemPrefixSpacing = 8
        return style
    }()

    /// The style used within the input bar.
    static var compact: DownStyle = {
        let style = DownStyle()
        style.baseFont = FontSpec.normalLightFont.font!
        style.baseFontColor = SemanticColors.Label.textDefault
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.codeColor = SemanticColors.Label.textDefault
        style.baseParagraphStyle = NSParagraphStyle.default
        style.listItemPrefixSpacing = 8

        // headers all same size
        style.h1Size = style.baseFont.pointSize
        style.h2Size = style.h1Size
        style.h3Size = style.h1Size
        return style
    }()

    /// The style used for the reply compose preview.
    static var preview: DownStyle = {
        let style = DownStyle()
        style.baseFont = UIFont.systemFont(ofSize: 14, contentSizeCategory: .medium, weight: .light)
        style.baseFontColor = SemanticColors.Label.textDefault
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.codeColor = SemanticColors.Label.textDefault
        style.baseParagraphStyle = NSParagraphStyle.default
        style.listItemPrefixSpacing = 8

        // headers all same size
        style.h1Size = style.baseFont.pointSize
        style.h2Size = style.h1Size
        style.h3Size = style.h1Size
        return style
    }()

    /// The style used during the login flow
    static var login: DownStyle = {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = .center
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.paragraphSpacingBefore = 8

        let style = DownStyle()
        style.baseFont = FontSpec.normalLightFont.font!
        style.baseFontColor = SemanticColors.Label.textDefault
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.codeColor = SemanticColors.Label.textDefault
        style.baseParagraphStyle = paragraphStyle
        style.listItemPrefixSpacing = 8
        return style
    }()
}
