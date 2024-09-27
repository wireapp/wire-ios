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

enum TweetOpeningOption: Int, LinkOpeningOption {
    case none, tweetbot, twitterrific

    typealias ApplicationOptionEnum = TweetOpeningOption
    static var settingKey: SettingKey = .twitterOpeningRawValue
    static var defaultPreference: ApplicationOptionEnum = .none

    var displayString: String {
        switch self {
        case .none: L10n.Localizable.OpenLink.Twitter.Option.default
        case .tweetbot: L10n.Localizable.OpenLink.Twitter.Option.tweetbot
        case .twitterrific: L10n.Localizable.OpenLink.Twitter.Option.twitterrific
        }
    }

    static var allOptions: [TweetOpeningOption] {
        [.none, .tweetbot, .twitterrific]
    }

    var isAvailable: Bool {
        switch self {
        case .none: true
        case .tweetbot: UIApplication.shared.tweetbotInstalled
        case .twitterrific: UIApplication.shared.twitterrificInstalled
        }
    }
}

extension URL {
    func openAsTweet() -> Bool {
        log.debug("Trying to open \"\(self)\" as tweet, isTweet: \(isTweet)")
        guard isTweet else { return false }
        let saved = TweetOpeningOption.storedPreference
        log.debug("Saved option to open a tweet: \(saved.displayString)")
        let app = UIApplication.shared

        switch saved {
        case .none: return false

        case .tweetbot:
            guard let url = tweetbotURL, app.canOpenURL(url) else { return false }
            log.debug("Trying to open tweetbot app using \"\(url)\"")
            app.open(url)

        case .twitterrific:
            guard let url = twitterrificURL, app.canOpenURL(url) else { return false }
            log.debug("Trying to open twitterific app using \"\(url)\"")
            app.open(url)
        }

        return true
    }
}

// MARK: - Private

extension UIApplication {
    fileprivate var tweetbotInstalled: Bool {
        canHandleScheme("tweetbot://")
    }

    fileprivate var twitterrificInstalled: Bool {
        canHandleScheme("twitterrific://")
    }
}

extension URL {
    var isTweet: Bool {
        absoluteString.contains("twitter.com") && absoluteString.contains("status")
    }
}

extension URL {
    private var tweetbotURL: URL? {
        guard isTweet else { return nil }

        let components = [
            "https://twitter.com/",
            "http://twitter.com/",
            "http://mobile.twitter.com/",
            "https://mobile.twitter.com/",
        ]

        let tweetbot = components.reduce(absoluteString) { result, current in
            result.replacingWithTweetbotURLScheme(current)
        }

        return URL(string: tweetbot)
    }

    private var twitterrificURL: URL? {
        tweetID.flatMap { URL(string: "twitterrific://current/tweet?id=\($0)") }
    }

    private var tweetID: String? {
        guard let statusRange = absoluteString.range(of: "status/") else { return nil }
        return String(absoluteString[statusRange.upperBound...])
    }
}

extension String {
    fileprivate func replacingWithTweetbotURLScheme(_ string: String) -> String {
        replacingOccurrences(of: string, with: "tweetbot://")
    }
}
