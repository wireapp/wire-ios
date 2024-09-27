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
import WireUtilities

extension Bundle {
    public var appInfo: Bundle.Info {
        Info(
            version: shortVersionString ?? "-",
            build: Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "-"
        )
    }

    public var shortVersionString: String? {
        Bundle.main.infoForKey("CFBundleShortVersionString")
    }

    public static var appMainBundle: Bundle {
        let mainBundle: Bundle
        if UIApplication.runningInExtension {
            let extensionBundleURL = Bundle.main.bundleURL
            let mainAppBundleURL = extensionBundleURL.deletingLastPathComponent().deletingLastPathComponent()
            guard let bundle = Bundle(url: mainAppBundleURL) else { fatalError("Failed to find main app bundle") }
            mainBundle = bundle
        } else {
            mainBundle = .main
        }
        return mainBundle
    }

    public struct Info: SafeForLoggingStringConvertible {
        // MARK: Public

        public var safeForLoggingDescription: String {
            "Wire-ios version \(version) (\(build)))"
        }

        public var fullVersion: String {
            "\(version) (\(build))"
        }

        // MARK: Internal

        var version: String
        var build: String
    }
}
