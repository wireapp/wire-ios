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
import WireSystem

public enum URLs {

    case appOnItunes
    case support
    case searchSupport
    case website
    case emailAlreadyInUse
    case whyToVerifyFingerprintArticle
    case howToVerifyFingerprintArticle
    case privacyPolicy // check localisation and why do we use it -> datenschutz
    case legal // check localisation -> nutzungsbedingungen
    case licenseInformation // doesn't work!!!
    case passwordResetInfo
    case askSupportArticle
    case reportAbuse
    case pricingInfo
    case wireEnterpriseInfo
    case legalHoldInfo
    case guestLinksInfo
    case unreachableBackendInfo
    case federationInfo
    case mlsInfo // doesn't work!!!
    case endToEndIdentityInfo // doesn't work!!!

    var bundleKey: String {
        switch self {
        case .appOnItunes:
            return "appOnItunes"
        case .support:
            return "support"
        case .searchSupport:
            return "searchSupport"
        case .website:
            return "website"
        case .emailAlreadyInUse:
            return "emailAlreadyInUse"
        case .whyToVerifyFingerprintArticle:
            return "whyToVerifyFingerprintArticle"
        case .howToVerifyFingerprintArticle:
            return "howToVerifyFingerprintArticle"
        case .privacyPolicy:
            return "privacyPolicy"
        case .legal:
            return "legal"
        case .licenseInformation:
            return "licenseInformation"
        case .passwordResetInfo:
            return "passwordResetInfo"
        case .askSupportArticle:
            return "askSupportArticle"
        case .reportAbuse:
            return "reportAbuse"
        case .pricingInfo:
            return "pricingInfo"
        case .wireEnterpriseInfo:
            return "wireEnterpriseInfo"
        case .legalHoldInfo:
            return "legalHoldInfo"
        case .guestLinksInfo:
            return "guestLinksInfo"
        case .unreachableBackendInfo:
            return "unreachableBackendInfo"
        case .federationInfo:
            return "federationInfo"
        case .mlsInfo:
            return "mlsInfo"
        case .endToEndIdentityInfo:
            return "endToEndIdentityInfo"
        }
    }

    public var url: URL {
        return URL(string: stringValue)!
    }

    private var stringValue: String {
        return Bundle.appMainBundle.infoForKey(bundleKey) ?? ""
    }

}

//    struct URLs1: Codable {
//        let appOnItunes: URL
//        let randomProfilePictureSource: URL
//        let emailAlreadyInUse: URL
//        let support: URL
//        let whyToVerifyFingerprintArticle: URL
//        let howToVerifyFingerprintArticle: URL
//        let termsOfUse: URL
//        let licenseInformation: URL
//        let website: URL
//        let passwordResetInfo: URL
//        let pricingInfo: URL
//        let wireEnterpriseInfo: URL
//        let endToEndIdentityInfo: URL
//        let mlsInfo: URL
//        let legalHoldInfo: URL
//        let federationInfo: URL
//        let unreachableBackendInfo: URL
//        let guestLinksInfo: URL
//        let reportAbuse: URL
//        let cannotDecryptMessageArticle: URL
//
//        static var shared: URLs1? = {
//            URLs1(forResource: "url", withExtension: "json")
//        }()
//
//        private init?(forResource resource: String, withExtension fileExtension: String) {
//            guard let fileURL = Bundle.fileURL(for: resource, with: fileExtension) else {
//                return nil
//            }
//
//            do {
//                self = try fileURL.decode(URLs1.self)
//            } catch {
//                return nil
//            }
//        }
//    }

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
     3. emailAlreadyInUse
     4. support
     5. whyToVerifyFingerprintArticle
     6. howToVerifyFingerprintArticle
     7. termsOfUse
     8. licenseInformation
     9. website
     10. passwordResetInfo
     11. pricingInfo
     12. wireEnterpriseInfo
     13. endToEndIdentityInfo
     14. mlsInfo
     15. legalHoldInfo
     16. federationInfo
     17. unreachableBackendInfo
     18. guestLinksInfo
     19. reportAbuse
     20. cannotDecryptMessageArticle


     13. wr_askSupport
     16. wr_cannotDecryptNewRemoteIDHelp
     17. wr_createTeamFeatures
     18. wr_emailInUseLearnMore
     19. wr_searchSupport
     20. wr_termsOfServicesURL
     28. selfUserProfileLink: BackendEnvironment.selfUserProfileLink
     30. websiteLink
     31. accountsLink
     32. termsOfServices
     33. privacyPolicy
     34. legal


     */
