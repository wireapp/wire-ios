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
import WireSyncEngine

final class BackgroundViewController: UIViewController {

    // MARK: - Constants

    private let backgroundScaleFactor: CGFloat = 1.4

    // MARK: - Properties

    var accentColor: UIColor {
        get { imageView.backgroundColor ?? .clear }
        set { imageView.backgroundColor = newValue }
    }

    // MARK: - Private Properties

    private let imageView = UIImageView()
    private let cropView = UIView()
    private let darkenOverlay = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let imageTransformer: ImageTransformer

    // MARK: - Life Cycle

    init(
        accentColor: UIColor,
        imageTransformer: ImageTransformer
    ) {
        self.imageTransformer = imageTransformer
        super.init(nibName: .none, bundle: .none)
        self.accentColor = accentColor
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        createConstraints()
    }

    private func configureViews() {

        imageView.contentMode = .scaleAspectFill
        imageView.transform = CGAffineTransform(scaleX: backgroundScaleFactor, y: backgroundScaleFactor)

        cropView.clipsToBounds = true
        [imageView, blurView, darkenOverlay].forEach(cropView.addSubview)
        view.addSubview(cropView)
    }

    private func createConstraints() {
        cropView.translatesAutoresizingMaskIntoConstraints = false
        blurView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        darkenOverlay.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            // Crop view
            cropView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -100),
            cropView.topAnchor.constraint(equalTo: view.topAnchor),
            cropView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 100),
            cropView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Blur view
            blurView.leadingAnchor.constraint(equalTo: cropView.leadingAnchor),
            blurView.topAnchor.constraint(equalTo: cropView.topAnchor),
            blurView.trailingAnchor.constraint(equalTo: cropView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: cropView.bottomAnchor),

            // Image view
            imageView.leadingAnchor.constraint(equalTo: cropView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: cropView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: cropView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: cropView.bottomAnchor),

            // Darken overlay
            darkenOverlay.leadingAnchor.constraint(equalTo: cropView.leadingAnchor),
            darkenOverlay.topAnchor.constraint(equalTo: cropView.topAnchor),
            darkenOverlay.trailingAnchor.constraint(equalTo: cropView.trailingAnchor),
            darkenOverlay.bottomAnchor.constraint(equalTo: cropView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    override var childForStatusBarStyle: UIViewController? { children.first }
    override var childForStatusBarHidden: UIViewController? { children.first }

    // MARK: - Methods

    func setBackgroundImage(_ image: UIImage?) async {
        guard let image else { return imageView.image = nil }

        imageView.image = await Task.detached(priority: .background) { [imageTransformer] in
            imageTransformer.adjustInputSaturation(value: 2, image: image)
        }.value
    }
}
