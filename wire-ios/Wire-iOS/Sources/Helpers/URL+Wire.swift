//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

struct WireURL: Codable {
    let wireAppOnItunes: URL
    let support: URL
    let randomProfilePictureSource: URL

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

    static var wr_wireAppOnItunes: URL {
        WireURL.shared.wireAppOnItunes
    }

    static var wr_randomProfilePictureSource: URL {
        WireURL.shared.randomProfilePictureSource
    }

    static var wr_emailAlreadyInUseLearnMore: URL {
        wr_support.appendingPathComponent("hc/en-us/articles/115004082129-My-email-address-is-already-in-use-and-I-cannot-create-an-account-What-can-I-do-")
    }

    static var wr_support: URL {
        WireURL.shared.support
    }

//    static var wr_usernameLearnMore: URL {
//        BackendEnvironment.websiteLink(path: "support/username")
//    }

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

    static var selfUserProfileLink: URL? {
        BackendEnvironment.selfUserProfileLink
    }

    static var wr_e2eiLearnMore: URL {
        return wr_support.appendingPathComponent("hc/articles/9211300150685-End-to-end-identity")
    }

}

// MARK: - BackendEnvironment Standard URLs

private extension BackendEnvironment {
    static func websiteLink(path: String) -> URL {
        shared.websiteURL.appendingPathComponent(path)
    }

    static func localizedWebsiteLink(forPage page: WebsitePages) -> URL {
        let languageCode = Locale.autoupdatingCurrent.languageCode
        let baseURL = shared.websiteURL

        switch page {
        case .termsOfServices, .privacyPolicy:
            let pathComponent = (languageCode == "de") ? "datenschutz" : "legal"
            return baseURL.appendingPathComponent(pathComponent)

        case .legal:
            let pathComponent = (languageCode == "de") ? "de/nutzungsbedingungen" : "legal"
            return baseURL.appendingPathComponent(pathComponent)
        }
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

/*
wr_wireAppOnItunes
wr_randomProfilePictureSource
wr_emailAlreadyInUseLearnMore
wr_support
wr_usernameLearnMore
wr_fingerprintLearnMore
wr_fingerprintHowToVerify
wr_privacyPolicy
wr_legal
wr_licenseInformation
wr_website
wr_passwordReset
wr_askSupport
wr_reportAbuse
wr_cannotDecryptHelp
wr_cannotDecryptNewRemoteIDHelp
wr_createTeamFeatures
wr_emailInUseLearnMore
wr_searchSupport
wr_termsOfServicesURL
wr_legalHoldLearnMore
wr_wirePricingLearnMore
wr_wireEnterpriseLearnMore
wr_guestLinksLearnMore
wr_unreachableBackendLearnMore
wr_FederationLearnMore
wr_mlsLearnMore
selfUserProfileLink: BackendEnvironment.selfUserProfileLink
wr_e2eiLearnMore
websiteLink
accountsLink
privacyPolicy
legal

 1. appOnItunes
 2. randomProfilePictureSource
 3. emailAlreadyInUseLearnMore
 4. support
 5. whyToVerifyFingerprintLearnMore
 6. howToVerifyFingerprintLearnMore
 7. termsOfUse
 8. licenseInformation
 9. website
 10. passwordReset

 13. wr_askSupport
 14. wr_reportAbuse
 15. wr_cannotDecryptHelp
 16. wr_cannotDecryptNewRemoteIDHelp
 17. wr_createTeamFeatures
 18. wr_emailInUseLearnMore
 19. wr_searchSupport
 20. wr_termsOfServicesURL
 21. wr_legalHoldLearnMore
 22. pricingLearnMore
 23. wr_wireEnterpriseLearnMore
 24. guestLinksLearnMore
 25. unreachableBackendLearnMore
 26. federationLearnMore
 27. wr_mlsLearnMore
 28. selfUserProfileLink: BackendEnvironment.selfUserProfileLink
 29. wr_e2eiLearnMore
 30. websiteLink
 31. accountsLink
 32. termsOfServices
 33. privacyPolicy
 34. legal


 */

struct URLs: Codable {
    let wireAppOnItunes: URL
    let support: URL
    let randomProfilePictureSource: URL

    static var shared: URLs = {
        URLs(forResource: "url", withExtension: "json")!
    }()

    private init?(forResource resource: String, withExtension fileExtension: String) {
        guard let fileURL = Bundle.fileURL(for: resource, with: fileExtension) else {
            return nil
        }

        do {
            self = try fileURL.decode(URLs.self)
        } catch {
            return nil
        }
    }
}
