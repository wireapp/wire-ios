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
import WireSystem

private let log = ZMSLog(tag: "link opening")

// MARK: - MapsOpeningOption

enum MapsOpeningOption: Int, LinkOpeningOption {
    case apple
    case google

    // MARK: Internal

    typealias ApplicationOptionEnum = MapsOpeningOption

    static var settingKey: SettingKey = .mapsOpeningRawValue
    static var defaultPreference: ApplicationOptionEnum = .apple

    static var allOptions: [MapsOpeningOption] {
        [.apple, .google]
    }

    var displayString: String {
        switch self {
        case .apple: L10n.Localizable.OpenLink.Maps.Option.apple
        case .google: L10n.Localizable.OpenLink.Maps.Option.google
        }
    }

    var isAvailable: Bool {
        switch self {
        case .apple: true
        case .google: UIApplication.shared.googleMapsInstalled
        }
    }
}

extension URL {
    func openAsLocation() -> Bool {
        log.debug("Trying to open \"\(self)\" as location")
        let saved = MapsOpeningOption.storedPreference
        log.debug("Saved option to open a location: \(saved.displayString)")

        switch saved {
        case .apple: return false
        case .google:
            guard UIApplication.shared.canOpenURL(self) else {
                return false
            }
            UIApplication.shared.open(self)
            return true
        }
    }
}

// MARK: - Private

extension UIApplication {
    fileprivate var googleMapsInstalled: Bool {
        canHandleScheme("comgooglemaps://")
    }
}
