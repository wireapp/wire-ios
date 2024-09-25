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
    @Published var handle: String

    init(
        profileLink: String,
        handle: String
    ) {
        self.profileLink = profileLink
        let qrCodeImage = QRCodeGenerator.generateQRCode(from: profileLink)
        let overlaySize = CGSize(width: qrCodeImage.size.width * 0.25, height: qrCodeImage.size.height * 0.25)
        self.profileLinkQRCode = qrCodeImage.addImageCentered(
            UIImage(resource: .Wire.roundIcon),
            overlaySize: overlaySize,
            borderWidth: 1,
            borderColor: .white
        )
        self.handle = "@" + handle
    }

}

private extension UIImage {

    func addImageCentered(
        _ overlayImage: UIImage,
        overlaySize: CGSize,
        borderWidth: CGFloat,
        borderColor: UIColor
    ) -> UIImage {
        let size = self.size

        let renderer = UIGraphicsImageRenderer(size: size)
        let combinedImage = renderer.image { context in
            self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

            let xPosition = (size.width - overlaySize.width) / 2
            let yPosition = (size.height - overlaySize.height) / 2

            let borderRect = CGRect(
                x: xPosition - borderWidth,
                y: yPosition - borderWidth,
                width: overlaySize.width + 2 * borderWidth,
                height: overlaySize.height + 2 * borderWidth
            )
            borderColor.setFill()
            context.cgContext.fill(borderRect)

            overlayImage.draw(in: CGRect(x: xPosition, y: yPosition, width: overlaySize.width, height: overlaySize.height))
        }

        return combinedImage
    }

}
