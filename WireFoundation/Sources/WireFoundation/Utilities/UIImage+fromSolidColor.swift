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

public import UIKit

public extension UIImage {

    static func from(solidColor color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: .init(width: 1, height: 1)).image { rendererContext in
            color.setFill()
            rendererContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}

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
        "1"//Bundle.appMainBundle.infoForKey(bundleKey)
    }

    public var isEnabled: Bool {
        stringValue == "1"
    }

}
//
//public extension Bundle {
//
//    var appInfo: Bundle.Info {
//        Info(
//            version: shortVersionString ?? "-",
//            build: Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "-"
//        )
//    }
//
//    var shortVersionString: String? {
//        Bundle.main.infoForKey("CFBundleShortVersionString")
//    }
//
////    static var appMainBundle: Bundle {
////        
////        let mainBundle: Bundle
////        if UIApplication.runningInExtension {
////            let extensionBundleURL = Bundle.main.bundleURL
////            let mainAppBundleURL = extensionBundleURL.deletingLastPathComponent().deletingLastPathComponent()
////            guard let bundle = Bundle(url: mainAppBundleURL) else { fatalError("Failed to find main app bundle") }
////            mainBundle = bundle
////        } else {
////            mainBundle = .main
////        }
////        return mainBundle
////    }
//
//    private static var isRunningInExtension: Bool {
//        return Bundle.main.bundlePath.hasSuffix(".appex")
//    }
//
//    static var appMainBundle: Bundle {
//        let isExtension = Bundle.main.bundlePath.hasSuffix(".appex")
//
//        if isExtension {
//            let extensionBundleURL = Bundle.main.bundleURL
//            let mainAppBundleURL = extensionBundleURL
//                .deletingLastPathComponent()
//                .deletingLastPathComponent()
//
//            guard let bundle = Bundle(url: mainAppBundleURL) else {
//                fatalError("Failed to find main app bundle")
//            }
//
//            return bundle
//        } else {
//            return .main
//        }
//    }
//
//    struct Info {
//        var version: String
//        var build: String
//
//        public var safeForLoggingDescription: String {
//            "Wire-ios version \(version) (\(build)))"
//        }
//
//        public var fullVersion: String {
//            "\(version) (\(build))"
//        }
//    }
//}
//
//public extension Bundle {
//    func infoForKey(_ key: String) -> String? {
//        infoDictionary?[key] as? String
//    }
//}
