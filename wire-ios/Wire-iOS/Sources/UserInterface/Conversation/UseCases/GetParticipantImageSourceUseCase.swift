//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireAccountImageUI
import WireDataModel
import WireDesign
import WireSyncEngine

class GetParticipantImageSourceUseCase: GetParticipantImageSourceUseCaseProtocol {

    private let repository: GetParticipantImageSourceRepositoryProtocol

    init(repository: GetParticipantImageSourceRepositoryProtocol) {
        self.repository = repository
    }

    @MainActor
    func invoke(user: UserType) async -> WireAccountImageUI.AccountImageSource? {
        // A blocked user shows the blocked badge as its avatar everywhere, matching the conversation
        // list (see `BadgeUserImageView`). `AccountImageView` has no badge support, so we hand it a
        // composed image: a black circle with the white block glyph centred (no accent tint).
        if user.isBlocked {
            return .image(Self.makeBlockedImage())
        }

        let image = await repository.invoke(user: user)
        if let image {
            return WireAccountImageUI.AccountImageSource.image(image)
        } else {
            return WireAccountImageUI.AccountImageSource.text(user.initials ?? "")
        }
    }

    private static func makeBlockedImage() -> UIImage {
        struct Cache {
            static let image: UIImage = {
                let side: CGFloat = 40
                let glyphSide = side * 0.5
                let glyph = StyleKitIcon.block.makeImage(size: .custom(glyphSide), color: .white)
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
                return renderer.image { context in
                    UIColor.black.setFill()
                    context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
                    glyph.draw(in: CGRect(
                        x: (side - glyphSide) / 2,
                        y: (side - glyphSide) / 2,
                        width: glyphSide,
                        height: glyphSide
                    ))
                }
            }()
        }

        return Cache.image
    }
}
