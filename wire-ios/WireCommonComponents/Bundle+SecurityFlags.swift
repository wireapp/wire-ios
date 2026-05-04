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

public enum SecurityFlags {

    case generateLinkPreviews
    case forceConstantBitRateCalls
    case customBackend
    case cameraRoll
    case maxNumberAccounts
    case fileSharing
    case locationSharing
    case forceCallKitDisabled
    case clipboard
    case collapseOwnMessages
    case openLinksExternally

    /// Whether encryption at rest is enabled and can't be disabled.

    case forceEncryptionAtRest

    /// The minimum TLS version supported by the app.

    case minTLSVersion

    /// Whether an embedded user agent should be used for IDP authentication.

    case useEmbeddedIDPUserAgent

    var bundleKey: String {
        switch self {
        case .maxNumberAccounts:
            "MaxNumberAccounts"
        case .generateLinkPreviews:
            "GenerateLinkPreviewEnabled"
        case .forceConstantBitRateCalls:
            "ForceCBREnabled"
        case .customBackend:
            "CustomBackendEnabled"
        case .cameraRoll:
            "CameraRollEnabled"
        case .forceEncryptionAtRest:
            "ForceEncryptionAtRestEnabled"
        case .fileSharing:
            "FileSharingEnabled"
        case .locationSharing:
            "LocationSharingEnabled"
        case .forceCallKitDisabled:
            "ForceCallKitDisabled"
        case .minTLSVersion:
            "MinTLSVersion"
        case .clipboard:
            "ClipboardEnabled"
        case .collapseOwnMessages:
            "CollapseOwnMessages"
        case .useEmbeddedIDPUserAgent:
            "UseEmbeddedIDPUserAgent"
        case .openLinksExternally:
            "OpenLinksExternally"
        }
    }

    public var intValue: Int? {
        guard let string = stringValue else { return nil }
        return Int(string)
    }

    public var stringValue: String? {
        Bundle.appMainBundle.infoForKey(bundleKey)
    }

    public var isEnabled: Bool {
        stringValue == "1"
    }

}
