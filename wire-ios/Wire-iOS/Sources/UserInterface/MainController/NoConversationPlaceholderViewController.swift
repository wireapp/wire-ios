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

import SwiftUI
import WireDesign

final class NoConversationPlaceholderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorTheme.Backgrounds.backgroundVariant

        let image = WireStyleKit.imageOfShield()
            .withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.24
        imageView.tintColor = SemanticColors.Label.textDefault
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        let constraints: [NSLayoutConstraint] = [

            imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            imageView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 3),
            imageView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 3),
            //            view.safeAreaLayoutGuide.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: imageView.trailingAnchor, multiplier: 3),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: imageView.bottomAnchor, multiplier: 3)
        ]
        constraints[0].priority = .defaultHigh
        constraints[1].priority = .defaultHigh
        NSLayoutConstraint.activate(constraints)
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    NoConversationPlaceholderViewController()
}
