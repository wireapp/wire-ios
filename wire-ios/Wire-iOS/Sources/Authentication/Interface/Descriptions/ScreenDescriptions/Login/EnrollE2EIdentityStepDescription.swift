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

typealias E2ei = L10n.Localizable.Registration.Signin.E2ei

/// The step informing the user that they need to enroll into end-2-end identity

class EnrollE2EIdentityStepDescription: AuthenticationStepDescription {
    let backButton: BackButtonDescription? = nil
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: NSAttributedString?
    let secondaryView: AuthenticationSecondaryViewDescription?
    let footerView: AuthenticationFooterViewDescription? = nil

    init() {
        self.mainView = SolidButtonDescription(
            title: E2ei.GetCertificateButton.title,
            accessibilityIdentifier: "get_certificate"
        )
        self.secondaryView = nil
        self.headline = E2ei.title
        let details = [E2ei.subtitle, E2ei.learnMore(WireURLs.shared.endToEndIdentityInfo)].joined(separator: "\n")
        self.subtext = .markdown(from: details, style: .login)
    }
}
