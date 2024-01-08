// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireUtilities

public extension Bundle {

    var appInfo: Bundle.Info {
        return Info(version: shortVersionString ?? "-", build: Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "-")
    }

    var shortVersionString: String? {
        return Bundle.main.infoForKey("CFBundleShortVersionString")
    }

    static var appMainBundle: Bundle {
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

    struct Info: SafeForLoggingStringConvertible {
        var version: String
        var build: String

        public var safeForLoggingDescription: String {
            "Wire-ios version \(version) (\(build)))"
        }
    }

}
