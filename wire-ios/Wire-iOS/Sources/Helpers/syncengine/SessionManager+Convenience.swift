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

import AVFoundation
import avs
import Foundation
import WireCommonComponents
import WireSyncEngine

extension SessionManager {
    static var shared: SessionManager? {
        AppDelegate.shared.appRootRouter?.sessionManager
    }

    static var numberOfAccounts: Int {
        SessionManager.shared?.accountManager.accounts.count ?? 0
    }

    var firstAuthenticatedAccount: Account? {
        firstAuthenticatedAccount(excludingCredentials: nil)
    }

    func firstAuthenticatedAccount(excludingCredentials credentials: LoginCredentials?) -> Account? {
        if let selectedAccount = accountManager.selectedAccount {
            if BackendEnvironment.shared.isAuthenticated(selectedAccount),
               selectedAccount.loginCredentials != credentials {
                return selectedAccount
            }
        }

        for account in accountManager.accounts {
            if BackendEnvironment.shared.isAuthenticated(account), account != accountManager.selectedAccount,
               account.loginCredentials != credentials {
                return account
            }
        }

        return nil
    }

    func updateCallNotificationStyleFromSettings() {
        let isCallKitDisabled = Settings.shared[.disableCallKit] == true || SecurityFlags.forceCallKitDisabled.isEnabled
        let isCallKitEnabled = !isCallKitDisabled
        let hasAudioPermissions = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == AVAuthorizationStatus
            .authorized
        let isCallKitSupported = !UIDevice.isSimulator

        if isCallKitEnabled, isCallKitSupported, hasAudioPermissions {
            callNotificationStyle = .callKit
        } else {
            callNotificationStyle = .pushNotifications
        }
    }

    func updateMuteOtherCallsFromSettings() {
        let isMuteCallEnabled: Bool = (Settings.shared[.muteIncomingCallsWhileInACall] ?? false)
        if isMuteCallEnabled {
            AVSMediaManager.sharedInstance().unregisterCallRingingSounds()
        } else {
            AVSMediaManager.sharedInstance().configureDefaultSounds()
        }
    }
}
