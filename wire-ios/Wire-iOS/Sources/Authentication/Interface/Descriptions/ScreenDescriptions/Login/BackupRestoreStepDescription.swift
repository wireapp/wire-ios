//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

/**
 * The view that displays the restore from backup button.
 */

class BackupRestoreStepDescriptionFooterView: AuthenticationFooterViewDescription {

    let views: [ViewDescriptor]
    weak var actioner: AuthenticationActioner?

    typealias NoHistory = L10n.Localizable.Registration.NoHistory

    init() {
        let restoreButton = SecondaryButtonDescription(title: NoHistory.restoreBackup.capitalized, accessibilityIdentifier: "restore_backup")
        views = [restoreButton]

        restoreButton.buttonTapped = { [weak self] in
            self?.actioner?.executeAction(.startBackupFlow)
        }
    }
}

/**
 * The step that displays information about the history.
 */

class BackupRestoreStepDescription: AuthenticationStepDescription {
    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: String?
    let secondaryView: AuthenticationSecondaryViewDescription?
    let footerView: AuthenticationFooterViewDescription?

    init(context: NoHistoryContext) {
        backButton = BackButtonDescription()
        mainView = SolidButtonDescription(title: "registration.no_history.got_it".localized, accessibilityIdentifier: "ignore_backup")
        secondaryView = nil
        switch context {
        case .newDevice:
            headline = "registration.no_history.hero".localized
            subtext = "registration.no_history.subtitle".localized
        case .loggedOut:
            headline = "registration.no_history.logged_out.hero".localized
            subtext = "registration.no_history.logged_out.subtitle".localized
        }

        guard SecurityFlags.backup.isEnabled else {
            footerView = nil
            return
        }

        footerView = BackupRestoreStepDescriptionFooterView()

    }

}
