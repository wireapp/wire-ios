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

extension NSTextAttachment {
    convenience init(imageResource: ImageResource) {
        self.init(image: .init(resource: imageResource))
    }

    static func textAttachment(
        for icon: StyleKitIcon,
        with color: UIColor,
        iconSize: StyleKitIcon.Size = 10,
        verticalCorrection: CGFloat = 0,
        insets: UIEdgeInsets? = nil
    ) -> NSTextAttachment {
        let image: UIImage = if let insets {
            icon.makeImage(size: iconSize, color: color).with(insets: insets, backgroundColor: .clear)!
        } else {
            icon.makeImage(size: iconSize, color: color)
        }

        let attachment = NSTextAttachment()
        attachment.image = image
        let ratio = image.size.width / image.size.height
        attachment.bounds = CGRect(
            x: 0,
            y: verticalCorrection,
            width: iconSize.rawValue * ratio,
            height: iconSize.rawValue
        )
        return attachment
    }
}
