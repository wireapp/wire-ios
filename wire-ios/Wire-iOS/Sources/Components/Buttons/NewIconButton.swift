//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireCommonComponents

enum NewIconButtonStyle {
    case `default`
    case circular
    case navigation
}

struct NewIconDefinition: Equatable {
    let type: UIImage
    let size: CGFloat
    let renderingMode: UIImage.RenderingMode
}

class NewIconButton: ButtonWithLargerHitArea {

    var fontSpec: FontSpec
    var iconButtonStyle: IconButtonStyle = .default {
        didSet { updateConfiguration() }
    }

    var iconDefinition: NewIconDefinition? {
        didSet { updateIcon() }
    }

    var borderWidth: CGFloat = 0.5 {
        didSet { updateConfiguration() }
    }

    override init(fontSpec: FontSpec = .normalRegularFont) {
        self.fontSpec = fontSpec
        super.init(fontSpec: fontSpec)
        hitAreaPadding = CGSize(width: 20, height: 20)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        // Initial configuration setup
        updateConfiguration()
    }

    override func updateConfiguration() {
        var config = UIButton.Configuration.plain()

        // Customize configuration based on buttonStyle
        switch iconButtonStyle {
        case .default:
            // Default style configuration
            break
        case .circular:
            configureCircularStyle()
        case .navigation:
            configureNavigationStyle()
        }

        self.configuration = config
        updateIcon()
    }

    var circular = false {
        didSet {
            updateConfiguration()
        }
    }

    private func configureNavigationStyle() {
        var config = UIButton.Configuration.plain()

        config.titlePadding = 5
        config.imagePadding = -5

        let attributes = AttributeContainer([.font: fontSpec.font!])
        let attributedString = AttributedString(self.currentTitle ?? "", attributes: attributes)

        config.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 5,
            bottom: 0,
            trailing: -5
        )
        config.imagePlacement = .leading

        self.configuration = config
    }

    private func configureCircularStyle() {
        var config = UIButton.Configuration.plain()

        config.cornerStyle = .capsule

        config.contentInsets = NSDirectionalEdgeInsets.zero
        config.titlePadding = 0
        config.imagePadding = 0

        // Apply the configuration
        self.configuration = config

        if circular {
            self.layer.masksToBounds = true
            self.layer.borderWidth = borderWidth
            updateCircularCornerRadius()
        } else {
            self.layer.masksToBounds = false
            self.layer.borderWidth = 0.0
            self.layer.cornerRadius = 0
        }
    }

    private func updateCircularCornerRadius() {
        self.layer.cornerRadius = self.bounds.height / 2
    }

    private func updateIcon() {
        guard let iconDef = iconDefinition else { return }
        let resizedImage = iconDef.type.resized(to: CGSize(width: iconDef.size, height: iconDef.size))
        self.configuration?.image = resizedImage.withRenderingMode(iconDef.renderingMode)
    }

}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? self
    }
}
