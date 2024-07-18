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

import Foundation

public enum SecurityFlags {

    case generateLinkPreviews
    case forceConstantBitRateCalls
    case customBackend
    case cameraRoll
    case backup
    case maxNumberAccounts
    case fileSharing
    case locationSharing
    case forceCallKitDisabled
    case clipboard

    /// Whether encryption at rest is enabled and can't be disabled.

    case forceEncryptionAtRest

    /// The minimum TLS version supported by the app.

    case minTLSVersion

    var bundleKey: String {
        switch self {
        case .maxNumberAccounts:
            return "MaxNumberAccounts"
        case .generateLinkPreviews:
            return "GenerateLinkPreviewEnabled"
        case .forceConstantBitRateCalls:
            return "ForceCBREnabled"
        case .customBackend:
            return "CustomBackendEnabled"
        case .cameraRoll:
            return "CameraRollEnabled"
        case .backup:
            return "BackupEnabled"
        case .forceEncryptionAtRest:
            return "ForceEncryptionAtRestEnabled"
        case .fileSharing:
            return "FileSharingEnabled"
        case .locationSharing:
            return "LocationSharingEnabled"
        case .forceCallKitDisabled:
            return "ForceCallKitDisabled"
        case .minTLSVersion:
            return "MinTLSVersion"
        case .clipboard:
            return "ClipboardEnabled"
        }
    }

    public var intValue: Int? {
        guard let string = stringValue else { return nil }
        return Int(string)
    }

    public var stringValue: String? {
        return Bundle.appMainBundle.infoForKey(bundleKey)
    }

    public var isEnabled: Bool {
        return stringValue == "1"
    }

}
