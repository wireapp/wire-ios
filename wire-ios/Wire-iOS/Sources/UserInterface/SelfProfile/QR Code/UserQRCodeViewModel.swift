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

import Foundation
import SwiftUI

final class UserQRCodeViewModel: ObservableObject {

    @Published var profileLink: String
    @Published var profileLinkQRCode: UIImage
    @Published var accentColor: Color
    @Published var handle: String

    init(
        profileLink: String,
        accentColor: Color,
        handle: String
    ) {
        self.profileLink = profileLink
        let qrCodeImage = QRCodeGenerator.generateQRCode(from: profileLink)
        self.profileLinkQRCode = qrCodeImage.addImageCentered(
            UIImage(resource: .Wire.roundIcon),
            borderWidth: 2,
            borderColor: .white
        )
        self.accentColor = accentColor
        self.handle = "@" + handle
    }

}

private extension UIImage {

    func addImageCentered(_ overlayImage: UIImage, borderWidth: CGFloat, borderColor: UIColor) -> UIImage {
        let size = CGSize(width: self.size.width, height: self.size.height)

        let renderer = UIGraphicsImageRenderer(size: size)
        let combinedImage = renderer.image { context in
            self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))

            let xPosition = (self.size.width - overlayImage.size.width) / 2
            let yPosition = (self.size.height - overlayImage.size.height) / 2

            let borderRect = CGRect(x: xPosition - borderWidth, y: yPosition - borderWidth, width: overlayImage.size.width + 2 * borderWidth, height: overlayImage.size.height + 2 * borderWidth)
            borderColor.setFill()
            context.cgContext.fill(borderRect)

            overlayImage.draw(in: CGRect(x: xPosition, y: yPosition, width: overlayImage.size.width, height: overlayImage.size.height))
        }

        return combinedImage
    }

}
