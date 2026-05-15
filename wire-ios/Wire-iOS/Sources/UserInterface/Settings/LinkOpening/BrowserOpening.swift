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

import UIKit
import WireSystem

private let log = ZMSLog(tag: "link opening")

enum BrowserOpeningOption: Int, LinkOpeningOption {

    case safari
    case chrome
    case firefox
    case snowhaze
    case brave

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
        isAvailable(using: UIApplication.shared)
    }

    func isAvailable(using application: any LinkOpeningApplication) -> Bool {
        switch self {
        case .safari: true
        case .chrome: application.chromeInstalled
        case .firefox: application.firefoxInstalled
        case .snowhaze: application.snowhazeInstalled
        case .brave: application.braveInstalled
        }
    }
}

extension URL {

    func openAsLink(using application: any LinkOpeningApplication = UIApplication.shared) -> Bool {
        log.debug("Trying to open \"\(self)\" in thrid party browser")
        let saved = BrowserOpeningOption.storedPreference
        log.debug("Saved option to open a regular link: \(saved.displayString)")

        switch saved {
        case .safari: return false
        case .chrome:
            guard let url = chromeURL, application.canOpenURL(url) else { return false }
            log.debug("Trying to open chrome app using \"\(url)\"")
            application.openURL(url)
        case .firefox:
            guard let url = firefoxURL, application.canOpenURL(url) else { return false }
            log.debug("Trying to open firefox app using \"\(url)\"")
            application.openURL(url)
        case .snowhaze:
            guard let url = snowhazeURL, application.canOpenURL(url) else { return false }
            log.debug("Trying to open snowhaze app using \"\(url)\"")
            application.openURL(url)
        case .brave:
            guard let url = braveURL, application.canOpenURL(url) else { return false }
            log.debug("Trying to open brave app using \"\(url)\"")
            application.openURL(url)
        }

        return true
    }

}

// MARK: - Private

private extension LinkOpeningApplication {

    var chromeInstalled: Bool {
        canHandleScheme("googlechrome://")
    }

    var firefoxInstalled: Bool {
        canHandleScheme("firefox://")
    }

    var snowhazeInstalled: Bool {
        canHandleScheme("shtps://")
    }

    var braveInstalled: Bool {
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
