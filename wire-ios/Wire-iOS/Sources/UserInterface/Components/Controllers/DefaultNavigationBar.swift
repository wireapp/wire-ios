//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

class DefaultNavigationBar: UINavigationBar, DynamicTypeCapable {

    func redrawFont() {
        titleTextAttributes?[.font] = FontSpec.smallSemiboldFont.font!
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    func configure() {
        tintColor = SemanticColors.Label.textDefault
        titleTextAttributes = DefaultNavigationBar.titleTextAttributes()
        configureBackground()
        let backIndicatorInsets = UIEdgeInsets(top: 0, left: 4, bottom: 2.5, right: 0)
        backIndicatorImage = StyleKitIcon.backArrow.makeImage(size: .tiny, color: SemanticColors.Icon.foregroundDefault).with(insets: backIndicatorInsets, backgroundColor: .clear)
        backIndicatorTransitionMaskImage = StyleKitIcon.backArrow.makeImage(size: .tiny, color: SemanticColors.Icon.foregroundDefault).with(insets: backIndicatorInsets, backgroundColor: .clear)
    }

    func configureBackground() {
        isTranslucent = false
        barTintColor = SemanticColors.View.backgroundDefault
        shadowImage = UIImage.singlePixelImage(with: UIColor.clear)
    }

    static func titleTextAttributes(for color: UIColor = SemanticColors.Label.textDefault) -> [NSAttributedString.Key: Any] {
        return [.font: FontSpec.smallSemiboldFont.font!,
                .foregroundColor: color,
                .baselineOffset: 1.0]
    }

}

extension UIViewController {
    func wrapInNavigationController(navigationControllerClass: UINavigationController.Type = RotationAwareNavigationController.self,
                                    navigationBarClass: AnyClass? = DefaultNavigationBar.self,
                                    setBackgroundColor: Bool = false) -> UINavigationController {
        let navigationController = navigationControllerClass.init(navigationBarClass: navigationBarClass, toolbarClass: nil)
        navigationController.setViewControllers([self], animated: false)

        if setBackgroundColor {
            navigationController.view.backgroundColor = SemanticColors.View.backgroundDefault
        }

        return navigationController
    }

    // MARK: - present
    func wrapInNavigationControllerAndPresent(from viewController: UIViewController) -> UINavigationController {
        let navigationController = wrapInNavigationController()
        navigationController.modalPresentationStyle = .formSheet
        viewController.present(navigationController, animated: true)

        return navigationController
    }

}
