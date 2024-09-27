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

// MARK: - BrowserOpeningOption

enum BrowserOpeningOption: Int, LinkOpeningOption {
    case safari, chrome, firefox, snowhaze, brave

    // MARK: Internal

    typealias ApplicationOptionEnum = BrowserOpeningOption

    static var settingKey: SettingKey = .browserOpeningRawValue
    static var defaultPreference: ApplicationOptionEnum = .safari

    static var allOptions: [BrowserOpeningOption] {
        [.safari, .chrome, .firefox, .snowhaze, .brave]
    }

    var displayString: String {
        switch self {
        case .safari:   L10n.Localizable.OpenLink.Browser.Option.safari
        case .chrome:   L10n.Localizable.OpenLink.Browser.Option.chrome
        case .firefox:  L10n.Localizable.OpenLink.Browser.Option.firefox
        case .snowhaze: L10n.Localizable.OpenLink.Browser.Option.snowhaze
        case .brave:    L10n.Localizable.OpenLink.Browser.Option.brave
        }
    }

    var isAvailable: Bool {
        switch self {
        case .safari: true
        case .chrome: UIApplication.shared.chromeInstalled
        case .firefox: UIApplication.shared.firefoxInstalled
        case .snowhaze: UIApplication.shared.snowhazeInstalled
        case .brave: UIApplication.shared.braveInstalled
        }
    }
}

extension URL {
    func openAsLink() -> Bool {
        log.debug("Trying to open \"\(self)\" in thrid party browser")
        let saved = BrowserOpeningOption.storedPreference
        log.debug("Saved option to open a regular link: \(saved.displayString)")
        let app = UIApplication.shared

        switch saved {
        case .safari: return false

        case .chrome:
            guard let url = chromeURL, app.canOpenURL(url) else { return false }
            log.debug("Trying to open chrome app using \"\(url)\"")
            app.open(url)

        case .firefox:
            guard let url = firefoxURL, app.canOpenURL(url) else { return false }
            log.debug("Trying to open firefox app using \"\(url)\"")
            app.open(url)

        case .snowhaze:
            guard let url = snowhazeURL, app.canOpenURL(url) else { return false }
            log.debug("Trying to open snowhaze app using \"\(url)\"")
            app.open(url)

        case .brave:
            guard let url = braveURL, app.canOpenURL(url) else { return false }
            log.debug("Trying to open brave app using \"\(url)\"")
            app.open(url)
        }

        return true
    }
}

// MARK: - Private

extension UIApplication {
    fileprivate var chromeInstalled: Bool {
        canHandleScheme("googlechrome://")
    }

    fileprivate var firefoxInstalled: Bool {
        canHandleScheme("firefox://")
    }

    fileprivate var snowhazeInstalled: Bool {
        canHandleScheme("shtps://")
    }

    fileprivate var braveInstalled: Bool {
        canHandleScheme("brave://")
    }
}

extension URL {
    var chromeURL: URL? {
        if absoluteString.contains("http://") {
            return URL(string: "googlechrome://\(absoluteString.replacingOccurrences(of: "http://", with: ""))")
        }
        if absoluteString.contains("https://") {
            return URL(string: "googlechromes://\(absoluteString.replacingOccurrences(of: "https://", with: ""))")
        }
        return URL(string: "googlechrome://\(absoluteString)")
    }

    var percentEncodingString: String {
        absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    }

    var firefoxURL: URL? {
        URL(string: "firefox://open-url?url=\(percentEncodingString)")
    }

    var snowhazeURL: URL? {
        // Reference: https://github.com/snowhaze/SnowHaze-iOS/blob/master/SnowHaze/Info.plist
        if absoluteString.contains("http://") {
            return URL(string: "shtp://\(absoluteString.replacingOccurrences(of: "http://", with: ""))")
        }
        if absoluteString.contains("https://") {
            return URL(string: "shtps://\(absoluteString.replacingOccurrences(of: "https://", with: ""))")
        }
        return URL(string: "shtp://\(absoluteString)")
    }

    var braveURL: URL? {
        // Reference: https://github.com/brave/ios-open-thirdparty-browser/blob/master/OpenInThirdPartyBrowser/OpenInThirdPartyBrowserControllerSwift.swift
        URL(string: "brave://open-url?url=\(percentEncodingString)")
    }
}
