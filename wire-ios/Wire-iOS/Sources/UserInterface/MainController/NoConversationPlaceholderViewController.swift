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

import SwiftUI
import WireDesign

struct NoConversationPlaceholderViewControllerBuilder {

    private let kmpViewModelEnvironment: KMPViewModelEnvironment

    init(kmpViewModelEnvironment: KMPViewModelEnvironment) {
        self.kmpViewModelEnvironment = kmpViewModelEnvironment
    }

    @MainActor
    func build() -> NoConversationPlaceholderViewController {
        if shouldBuildKMPViewModelImplementation {
            return buildKMPViewModelImplementation()
        }

        return buildLegacy()
    }

    private var shouldBuildKMPViewModelImplementation: Bool {
        kmpViewModelEnvironment.usesKMPViewModel(
            for: .noConversationPlaceholder,
            isKMPImplementationAvailable: false
        )
    }

    @MainActor
    private func buildKMPViewModelImplementation() -> NoConversationPlaceholderViewController {
        // KMP-backed implementation will be added once Metro/Kalium exposes this screen contract.
        buildLegacy()
    }

    @MainActor
    private func buildLegacy() -> NoConversationPlaceholderViewController {
        NoConversationPlaceholderViewController()
    }
}

final class NoConversationPlaceholderViewController: UIViewController {

    private let viewModel: NoConversationPlaceholderViewModel

    init(viewModel: NoConversationPlaceholderViewModel = NoConversationPlaceholderViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        render(viewModel.displayState)
    }

    private func render(_ displayState: NoConversationPlaceholderViewModel.DisplayState) {
        view.backgroundColor = ColorTheme.Backgrounds.backgroundVariant

        let image = image(for: displayState.imageAsset)
            .withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = CGFloat(displayState.imageAlpha)
        imageView.tintColor = SemanticColors.Label.textDefault
        imageView.isAccessibilityElement = displayState.imageAccessibility.isAccessibilityElement
        imageView.accessibilityLabel = displayState.imageAccessibility.label
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        let constraints: [NSLayoutConstraint] = [

            imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            imageView.leadingAnchor.constraint(
                greaterThanOrEqualToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor,
                multiplier: 3
            ),
            imageView.topAnchor.constraint(
                greaterThanOrEqualToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor,
                multiplier: 3
            ),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(
                greaterThanOrEqualToSystemSpacingBelow: imageView.bottomAnchor,
                multiplier: 3
            )
        ]
        constraints[0].priority = .defaultHigh
        constraints[1].priority = .defaultHigh
        NSLayoutConstraint.activate(constraints)
    }

    private func image(for asset: NoConversationPlaceholderViewModel.ImageAsset) -> UIImage {
        switch asset {
        case .shield:
            WireStyleKit.imageOfShield()
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    NoConversationPlaceholderViewController()
}
