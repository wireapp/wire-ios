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

import FLAnimatedImage

// MARK: - MediaAsset

protocol MediaAsset: AnyObject {
    var imageData: Data? { get }
    var size: CGSize { get }
    var isGIF: Bool { get }
    var isTransparent: Bool { get }
}

extension MediaAsset {
    var imageView: MediaAssetView {
        if isGIF {
            let animatedImageView = FLAnimatedImageView()
            animatedImageView.animatedImage = self as? FLAnimatedImage

            return animatedImageView
        } else {
            return UIImageView(image: (self as? UIImage)?.downsized())
        }
    }
}

// MARK: - MediaAssetView

protocol MediaAssetView: UIView {
    var mediaAsset: MediaAsset? { get set }
}

extension MediaAssetView where Self: UIImageView {
    var mediaAsset: MediaAsset? {
        get {
            image
        }
        set {
            if newValue == nil {
                image = nil
            } else if newValue?.isGIF == false {
                image = (newValue as? UIImage)?.downsized()
            }
        }
    }
}

extension MediaAssetView where Self: FLAnimatedImageView {
    var mediaAsset: MediaAsset? {
        get {
            animatedImage ?? image
        }

        set {
            if let newValue {
                if newValue.isGIF == true {
                    animatedImage = newValue as? FLAnimatedImage
                } else {
                    image = (newValue as? UIImage)?.downsized()
                }
            } else {
                image = nil
                animatedImage = nil
            }
        }
    }
}

// MARK: - FLAnimatedImage + MediaAsset

extension FLAnimatedImage: MediaAsset {
    var imageData: Data? {
        data
    }

    var isGIF: Bool {
        true
    }

    var isTransparent: Bool {
        false
    }
}

// MARK: - UIImageView + MediaAssetView

extension UIImageView: MediaAssetView {
    var imageData: Data? {
        get {
            image?.imageData
        }

        set {
            if let imageData = newValue {
                image = UIImage(data: imageData)
            }
        }
    }
}
