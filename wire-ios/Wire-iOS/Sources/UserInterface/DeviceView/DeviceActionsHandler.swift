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

final class DeviceDetailsActionsHandler: DeviceDetailsViewActions {
    var isDeviceVerified: Bool = false

    func fetchCertificate() async {
        print("Fetch certificate is tapped")
    }

    func showCertificate(validate: () -> Bool, result: (Bool) -> Void) {
        print("show certificate is called")
        result(validate())
    }

    func removeDevice() {
        print("Remove Device is called")
    }

    func resetSession() {
        print("Reset Session is called")
    }

    func setVerified(_ result: (Bool) -> Void) {
        print("set Verified is called")
        isDeviceVerified.toggle()
        result(isDeviceVerified)
    }

    func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
    }

}
