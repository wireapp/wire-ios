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

import Foundation
import UIKit
import WireNetwork
import WireSyncEngine

/// Top level dependencies needed app wide.
///
/// - warning: This is really only intended to be accessed by App delegates and scene delegates. In other places,
/// dependencies should be injected.
enum AppDependencies {

    static let cookieStorage = CookieStorage(cookieEncryptionKey: UserDefaults.cookiesKey())
    static let pushTokenService = PushTokenService()
    static let voIPPushManager = VoIPPushManager(application: UIApplication.shared)

}
