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
import WireTransport

private enum WebsitePages {
    case termsOfServices
    case privacyPolicy
    case legal
}

enum TeamSource: Int {
    case onboarding, settings

    var parameterValue: String {
        switch self {
        case .onboarding: return "client_landing"
        case .settings: return "client_settings"
        }
    }
}

<<<<<<< HEAD
struct WireURL: Codable {
    let wireAppOnItunes: URL
    let support: URL

    static var shared: WireURL! = {
        WireURL(filePath: Bundle.fileURL(for: "url", with: "json")!)
    }()

    private init?(filePath: URL) {
        do {
            self = try filePath.decode(WireURL.self)
        } catch {
            return nil
        }
    }
}

=======
>>>>>>> 174fe5b822 (feat: Update/move URLs for C1 and C3 WPB-9748 (#1718))
extension URL {

    var appendingLocaleParameter: URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        let localeQueryItem = URLQueryItem(name: "hl", value: Locale.current.identifier)

        var queryItems = components.queryItems ?? []
        queryItems.append(localeQueryItem)
        components.queryItems = queryItems

        return components.url ?? self
    }

    static func manageTeam(source: TeamSource) -> URL {
        let baseURL = BackendEnvironment.shared.teamsURL

        let queryItems = [URLQueryItem(name: "utm_source", value: source.parameterValue),
                          URLQueryItem(name: "utm_term", value: "ios")]

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)

        components?.queryItems = queryItems

        return components!.url!.appendingLocaleParameter
    }
}

// MARK: - Wire URLs

extension URL {

<<<<<<< HEAD
    static var wr_wireAppOnItunes: URL {
        WireURL.shared.wireAppOnItunes
    }

    static var wr_emailAlreadyInUseLearnMore: URL {
        wr_support.appendingPathComponent("hc/en-us/articles/115004082129-My-email-address-is-already-in-use-and-I-cannot-create-an-account-What-can-I-do-")
    }

    static var wr_support: URL {
        WireURL.shared.support
    }

    static var wr_usernameLearnMore: URL {
        BackendEnvironment.websiteLink(path: "support/username")
    }

    static var wr_fingerprintLearnMore: URL {
        wr_support.appendingPathComponent("hc/articles/207859815-Why-should-I-verify-my-conversations")
    }

    static var wr_fingerprintHowToVerify: URL {
        wr_support.appendingPathComponent("hc/articles/207692235-How-can-I-compare-key-fingerprints-")
    }

    static var wr_privacyPolicy: URL {
        BackendEnvironment.localizedWebsiteLink(forPage: .privacyPolicy)
    }

    static var wr_legal: URL {
        BackendEnvironment.localizedWebsiteLink(forPage: .legal)
    }

    static var wr_licenseInformation: URL {
        BackendEnvironment.websiteLink(path: "legal/licenses/embed")
    }

    static var wr_website: URL {
        BackendEnvironment.shared.websiteURL
    }

    static var wr_passwordReset: URL {
        BackendEnvironment.accountsLink(path: "forgot")
    }

    static var wr_askSupport: URL {
        wr_support.appendingPathComponent("hc/requests/new")
    }

    static var wr_reportAbuse: URL {
        wr_support.appendingPathComponent("hc/requests/new")
    }

    static var wr_cannotDecryptHelp: URL {
        BackendEnvironment.websiteLink(path: "privacy/error-1")
    }

    static var wr_cannotDecryptNewRemoteIDHelp: URL {
        BackendEnvironment.websiteLink(path: "privacy/error-2")
    }

    static var wr_createTeamFeatures: URL {
        BackendEnvironment.websiteLink(path: "teams/learnmore")
    }

    static var wr_emailInUseLearnMore: URL {
        BackendEnvironment.websiteLink(path: "support/email-in-use")
    }

    static var wr_searchSupport: URL {
        BackendEnvironment.websiteLink(path: "support/username") // TODO jacob update URL when new support page for search exists
    }

    static var wr_termsOfServicesURL: URL {
        BackendEnvironment.localizedWebsiteLink(forPage: .termsOfServices)
    }

    static var wr_legalHoldLearnMore: URL {
        wr_support.appendingPathComponent("hc/articles/360002018278-What-is-legal-hold-")
    }

    static var wr_wirePricingLearnMore: URL {
        BackendEnvironment.websiteLink(path: "pricing")
    }

    static var wr_wireEnterpriseLearnMore: URL {
        BackendEnvironment.websiteLink(path: "pricing")
    }

    static var wr_guestLinksLearnMore: URL {
        wr_support.appendingPathComponent("hc/articles/360000574069-Share-a-link-with-a-person-without-a-Wire-account-to-join-a-guest-room-conversation-in-my-team")
    }

    static var wr_unreachableBackendLearnMore: URL {
        wr_support.appendingPathComponent("hc/articles/9357718008093-Backend")
    }

    static var wr_FederationLearnMore: URL {
        wr_support.appendingPathComponent("hc/categories/4719917054365-Federation")
    }

    static var wr_mlsLearnMore: URL {
        wr_support.appendingPathComponent("hc/articles/12434725011485-Messaging-Layer-Security-MLS-")
    }

=======
>>>>>>> 174fe5b822 (feat: Update/move URLs for C1 and C3 WPB-9748 (#1718))
    static var selfUserProfileLink: URL? {
        BackendEnvironment.selfUserProfileLink
    }

}

// MARK: - BackendEnvironment Standard URLs

private extension BackendEnvironment {
    static func websiteLink(path: String) -> URL {
        shared.websiteURL.appendingPathComponent(path)
    }

    static func accountsLink(path: String) -> URL {
        shared.accountsURL.appendingPathComponent(path)
    }

    static var selfUserProfileLink: URL? {
        guard let userID = SelfUser.provider?.providedSelfUser.remoteIdentifier?.uuidString else {
            return nil
        }
        return shared.accountsURL.appendingPathComponent("user-profile/?id=\(userID)")
    }

}
