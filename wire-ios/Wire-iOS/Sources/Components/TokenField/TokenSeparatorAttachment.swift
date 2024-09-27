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

final class TokenSeparatorAttachment: NSTextAttachment, TokenContainer {
    // MARK: Lifecycle

    init(token: Token<NSObjectProtocol>, tokenField: TokenField) {
        self.token = token
        self.tokenField = tokenField

        super.init(data: nil, ofType: nil)

        refreshImage(tintColor: dotColor ?? ViewColors.backgroundDefaultBlack)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    typealias ViewColors = SemanticColors.View

    let token: Token<NSObjectProtocol>

    override var accessibilityLabel: String? {
        get {
            // Setting isAccessibilityElement to false does not seem to work for this
            // `NSTextAttachment`. VoiceOver will still dictate “Attachment. PNG. File” which is
            // really weird. Returning an empty label here so nothing will just be dictated at all.
            " "
        }
        set {
            super.accessibilityLabel = newValue
        }
    }

    // MARK: Private

    private unowned let tokenField: TokenField
    private let dotSize: CGFloat = 4
    private let dotSpacing: CGFloat = 8

    private var dotColor: UIColor? {
        tokenField.dotColor
    }

    private var backgroundColor: UIColor? {
        tokenField.tokenBackgroundColor
    }

    private var imageForCurrentToken: UIImage? {
        let imageHeight: CGFloat = ceil(tokenField.font.pointSize)
        let imageSize = CGSize(width: dotSize + dotSpacing * 2, height: imageHeight)
        let lineHeight = tokenField.fontLineHeight
        let delta: CGFloat = ceil((lineHeight - imageHeight) * 0.5 - tokenField.tokenTitleVerticalAdjustment)

        bounds = CGRect(x: 0, y: delta, width: imageSize.width, height: imageSize.height)

        UIGraphicsBeginImageContextWithOptions(bounds.size, _: false, _: 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.saveGState()

        if let backgroundColor {
            context.setFillColor(backgroundColor.cgColor)
        }
        context.setLineJoin(.round)
        context.setLineWidth(1)

        // draw dot
        let dotPath = UIBezierPath(ovalIn: CGRect(
            x: dotSpacing,
            y: ceil((imageSize.height + dotSize) / 2),
            width: dotSize,
            height: dotSize
        ))

        if let dotColor {
            context.setFillColor(dotColor.cgColor)
        }
        context.addPath(dotPath.cgPath)
        context.fillPath()

        let i = UIGraphicsGetImageFromCurrentImageContext()

        context.restoreGState()
        UIGraphicsEndImageContext()

        return i
    }

    private func refreshImage(tintColor: UIColor = ViewColors.backgroundDefaultBlack) {
        image = imageForCurrentToken?.withTintColor(tintColor)
    }
}
