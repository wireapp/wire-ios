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

    var accentColor: UIColor {
        get { imageView.backgroundColor ?? .clear }
        set { imageView.backgroundColor = newValue }
    }

    var backgroundImage: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }

    lazy private(set) var dispatchGroup = DispatchGroup()

    private let imageView = UIImageView()
    private let cropView = UIView()
    private let darkenOverlay = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let user: UserType
    private var userObserverToken: NSObjectProtocol?

    init(
        accentColor: UIColor,
        user: UserType,
        userSession: UserSession?
    ) {
        self.user = user
        super.init(nibName: .none, bundle: .none)
        self.accentColor = accentColor

        setupObservers(userSession: userSession)
    }

    private func setupObservers(userSession: UserSession?) {
        guard !ProcessInfo.processInfo.isRunningTests else { return }

        userObserverToken = userSession?.addUserObserver(self, for: user)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureViews()
        self.createConstraints()

        self.updateForUser()
    }

    override var childForStatusBarStyle: UIViewController? { children.first }
    override var childForStatusBarHidden: UIViewController? { children.first }

    private func configureViews() {

        let factor = BackgroundViewController.backgroundScaleFactor
        imageView.contentMode = .scaleAspectFill
        imageView.transform = CGAffineTransform(scaleX: factor, y: factor)

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

    private func updateForUser() {
        guard isViewLoaded else { return }

        Task { await updateForUserImage() }
    }

    private func updateForUserImage() async {
        guard let imageData = user.imageData(for: .complete) else { return }

        imageView.image = await Task.detached(priority: .background) {
            UIImage(from: imageData, withMaxSize: 40)?.desaturatedImage(with: CIContext.shared, saturation: 2)
        }.value
    }

    /*private*/ func updateFor(imageMediumDataChanged: Bool, accentColorValueChanged: Bool) {

        if imageMediumDataChanged {
            Task { await updateForUserImage() }
        }
    }

    private static let backgroundScaleFactor: CGFloat = 1.4

    private static func blurredAppBackground(with imageData: Data) -> UIImage? {
        .init(from: imageData, withMaxSize: 40)?.desaturatedImage(with: CIContext.shared, saturation: 2)
    }
}

extension BackgroundViewController: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.imageMediumDataChanged {
            Task { await updateForUserImage() }
        }
    }
}
