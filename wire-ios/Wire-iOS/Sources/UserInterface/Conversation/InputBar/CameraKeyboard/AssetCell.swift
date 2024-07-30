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

import Photos
import UIKit
import WireCommonComponents
import WireDesign

final class AssetCell: UICollectionViewCell {

    let imageView = UIImageView()
    let durationView = UILabel()

    var imageRequestTag: PHImageRequestID = PHInvalidImageRequestID
    var representedAssetIdentifier: String!
    var manager: ImageManagerProtocol!

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor(white: 0, alpha: 0.1)
        contentView.addSubview(imageView)

        durationView.textAlignment = .center
        durationView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        durationView.textColor = UIColor.white
        durationView.font = FontSpec(.small, .light).font!
        contentView.addSubview(durationView)

        [imageView, durationView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
          imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
          imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
          imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
          imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
          durationView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
          durationView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
          durationView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
          durationView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static let imageFetchOptions: PHImageRequestOptions = {
        let options: PHImageRequestOptions = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false
        return options
    }()

    var asset: PHAsset? {
        didSet {
            imageView.image = nil

            if imageRequestTag != PHInvalidImageRequestID {
                manager.cancelImageRequest(imageRequestTag)
                imageRequestTag = PHInvalidImageRequestID
            }

            guard let asset else {
                durationView.text = ""
                durationView.isHidden = true
                return
            }

            guard let keyWindow = AppDelegate.shared.keyWindow else { return }
            let maxDimensionRetina = max(bounds.size.width, bounds.size.height) * (window ?? keyWindow).screen.scale

            representedAssetIdentifier = asset.localIdentifier
            imageRequestTag = manager.requestImage(for: asset,
                                                   targetSize: CGSize(width: maxDimensionRetina, height: maxDimensionRetina),
                                                   contentMode: .aspectFill,
                                                   options: type(of: self).imageFetchOptions,
                                                   resultHandler: { [weak self] result, _ in
                                                    guard let self,
                                                        self.representedAssetIdentifier == asset.localIdentifier
                                                        else { return }
                                                    self.imageView.image = result
            })

            if asset.mediaType == .video {
                let duration = Int(ceil(asset.duration))

                let (seconds, minutes) = (duration % 60, duration / 60)
                durationView.text = String(format: "%d:%02d", minutes, seconds)
                durationView.isHidden = false
            } else {
                durationView.text = ""
                durationView.isHidden = true
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        asset = .none
    }
}
