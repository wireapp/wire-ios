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
import Foundation
import WireDataModel

final class ImageResourceView: FLAnimatedImageView {

    // MARK: - context menu
    weak var delegate: ContextMenuDelegate?
    private lazy var messagePresenter: MessagePresenter = {
        let messagePresenter = MessagePresenter(mediaPlaybackManager: nil)
        messagePresenter.modalTargetController = UIApplication.shared.wr_keyWindow?.rootViewController
        return messagePresenter
    }()

    fileprivate var loadingView = ThreeDotsLoadingView()

    /// This token is changes everytime the cell is re-used. Useful when performing
    /// asynchronous tasks where the cell might have been re-used in the mean time.
    fileprivate var reuseToken = UUID()
    fileprivate var imageResourceInternal: WireImageResource?

    var imageSizeLimit: ImageSizeLimit = .deviceOptimized
    var imageResource: WireImageResource? {
        get {
            return imageResourceInternal
        }

        set {
            setImageResource(newValue)
        }
    }

    func setImageResource(_ imageResource: WireImageResource?,
                          hideLoadingView: Bool = false,
                          completion: Completion? = nil) {
        let token = UUID()
        mediaAsset = nil

        imageResourceInternal = imageResource
        reuseToken = token
        loadingView.isHidden = hideLoadingView || loadingView.isHidden || imageResource == nil

        guard let imageResource = imageResource, imageResource.cacheIdentifier != nil else {
            loadingView.isHidden = true
            completion?()
            return
        }

        imageResource.fetchImage(sizeLimit: imageSizeLimit, completion: { [weak self] mediaAsset, cacheHit in
            guard token == self?.reuseToken, let `self` = self else { return }

            let update = {
                self.loadingView.isHidden = hideLoadingView || mediaAsset != nil
                self.mediaAsset = mediaAsset
                completion?()
            }

            if cacheHit || ProcessInfo.processInfo.isRunningTests {
                update()
            } else {
                UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve, animations: update)
            }
        })
    }

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        loadingView.accessibilityIdentifier = "loading"

        addSubview(loadingView)

        [self, loadingView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
