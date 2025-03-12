//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireAuthenticationAPI
import WireReusableUIComponents

@MainActor
package final class OnPremHeaderViewModel: ObservableObject {

    let backendName: String
    let backendURL: URL

    package init(backendName: String, backendURL: URL) {
        self.backendName = backendName
        self.backendURL = backendURL
    }

    var backendInfo: String {
        [
            L10n.OnPremUserLogin.Alert.Message.backendName,
            backendName,
            "",
            L10n.OnPremUserLogin.Alert.Message.backendUrl,
            backendURL.absoluteString
        ].joined(separator: "\n")
    }

}
