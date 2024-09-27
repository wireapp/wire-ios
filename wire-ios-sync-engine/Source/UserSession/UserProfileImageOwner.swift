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
import WireImages

public final class UserProfileImageOwner: NSObject, ZMImageOwner {
    // MARK: Lifecycle

    init(imageData: Data) {
        self.imageData = imageData
        super.init()
    }

    // MARK: Public

    public func setImageData(_ imageData: Data, for format: ZMImageFormat, properties: ZMIImageProperties?) {
        processedImages[format] = imageData
    }

    public func imageData(for format: ZMImageFormat) -> Data? {
        processedImages[format]
    }

    public func requiredImageFormats() -> NSOrderedSet {
        NSOrderedSet(array: UserProfileImageOwner.imageFormats.map(\.rawValue))
    }

    public func originalImageData() -> Data? {
        imageData
    }

    public func originalImageSize() -> CGSize {
        .zero
    }

    public func isInline(for format: ZMImageFormat) -> Bool {
        false
    }

    public func isPublic(for format: ZMImageFormat) -> Bool {
        false
    }

    public func isUsingNativePush(for format: ZMImageFormat) -> Bool {
        false
    }

    public func processingDidFinish() {}

    // MARK: Internal

    static var imageFormats: [ZMImageFormat] {
        [.medium, .profile]
    }

    let imageData: Data
    var processedImages = [ZMImageFormat: Data]()
}
