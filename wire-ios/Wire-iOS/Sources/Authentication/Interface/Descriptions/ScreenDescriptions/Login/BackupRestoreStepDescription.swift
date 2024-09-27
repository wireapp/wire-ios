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

// MARK: - BackupRestoreStepDescriptionFooterView

/// The view that displays the restore from backup button.

final class BackupRestoreStepDescriptionFooterView: AuthenticationFooterViewDescription {
    let views: [ViewDescriptor]
    weak var actioner: AuthenticationActioner?

    typealias NoHistory = L10n.Localizable.Registration.NoHistory

    init() {
        let restoreButton = SecondaryButtonDescription(
            title: NoHistory.restoreBackup.capitalized,
            accessibilityIdentifier: "restore_backup"
        )
        self.views = [restoreButton]

        restoreButton.buttonTapped = { [weak self] in
            self?.actioner?.executeAction(.startBackupFlow)
        }
    }
}

// MARK: - BackupRestoreStepDescription

/// The step that displays information about the history.

final class BackupRestoreStepDescription: AuthenticationStepDescription {
    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: NSAttributedString?
    let secondaryView: AuthenticationSecondaryViewDescription?
    let footerView: AuthenticationFooterViewDescription?

    init(context: NoHistoryContext) {
        self.backButton = BackButtonDescription()
        self.mainView = SolidButtonDescription(
            title: L10n.Localizable.Registration.NoHistory.gotIt,
            accessibilityIdentifier: "ignore_backup"
        )
        self.secondaryView = nil
        switch context {
        case .newDevice:
            self.headline = L10n.Localizable.Registration.NoHistory.hero
            self.subtext = .markdown(from: L10n.Localizable.Registration.NoHistory.subtitle, style: .login)

        case .loggedOut:
            self.headline = L10n.Localizable.Registration.NoHistory.LoggedOut.hero
            self.subtext = .markdown(from: L10n.Localizable.Registration.NoHistory.LoggedOut.subtitle, style: .login)
        }

        guard SecurityFlags.backup.isEnabled else {
            self.footerView = nil
            return
        }

        self.footerView = BackupRestoreStepDescriptionFooterView()
    }
}
