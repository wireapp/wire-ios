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
import WireCommonComponents

extension PermissionDeniedViewController {

    class func pushDeniedViewController() -> PermissionDeniedViewController {
        // MARK: - Properties
        typealias RegistrationPushAccessDenied = L10n.Localizable.Registration.PushAccessDenied
        let vc = PermissionDeniedViewController()
        let title = RegistrationPushAccessDenied.Hero.title
        let paragraph1 = RegistrationPushAccessDenied.Hero.paragraph1

        let text = [title, paragraph1].joined(separator: "\u{2029}")

        let attributedText = text.withCustomParagraphSpacing()

        attributedText.addAttributes([
            NSAttributedString.Key.font: FontSpec.largeThinFont.font!
        ], range: (text as NSString).range(of: paragraph1))
        attributedText.addAttributes([
            NSAttributedString.Key.font: FontSpec.largeSemiboldFont.font!
        ], range: (text as NSString).range(of: title))
        vc.heroLabel.attributedText = attributedText

        vc.settingsButton.setTitle(RegistrationPushAccessDenied.SettingsButton.title.capitalized, for: .normal)

        vc.laterButton.setTitle(RegistrationPushAccessDenied.MaybeLaterButton.title.capitalized, for: .normal)

        return vc
    }
}
