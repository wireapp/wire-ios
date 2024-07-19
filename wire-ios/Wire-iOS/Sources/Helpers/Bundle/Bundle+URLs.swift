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

struct URLs: Codable {

    let appOnItunes: URL
    let support: URL
    let searchSupport: URL
    let website: URL
    let emailAlreadyInUse: URL
    let whyToVerifyFingerprintArticle: URL
    let howToVerifyFingerprintArticle: URL
    let privacyPolicy: URL
    let legal: URL
    let licenseInformation: URL
    let passwordResetInfo: URL
    let askSupportArticle: URL
    let reportAbuse: URL
    let pricingInfo: URL
    let wireEnterpriseInfo: URL
    let legalHoldInfo: URL
    let guestLinksInfo: URL
    let unreachableBackendInfo: URL
    let federationInfo: URL
    let mlsInfo: URL
    let endToEndIdentityInfo: URL

    static var shared: URLs = {
        guard let urls = URLs(forResource: "url", withExtension: "json") else {
            fatalError("can't find or decode url.json")
        }

        return urls
    }()

    private init?(forResource resource: String, withExtension fileExtension: String) {
        guard let fileURL = Bundle.fileURL(for: resource, with: fileExtension) else {
            WireLogger.environment.error("no url.json file")

            return nil
        }
        do {
            self = try fileURL.decode(URLs.self)
        } catch {
            WireLogger.environment.error("can't decode url.json")

            return nil
        }
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case appOnItunes
        case support
        case searchSupport
        case website
        case emailAlreadyInUse
        case whyToVerifyFingerprintArticle
        case howToVerifyFingerprintArticle
        case privacyPolicy
        case legal
        case licenseInformation
        case passwordResetInfo
        case askSupportArticle
        case reportAbuse
        case pricingInfo
        case wireEnterpriseInfo
        case legalHoldInfo
        case guestLinksInfo
        case unreachableBackendInfo
        case federationInfo
        case mlsInfo
        case endToEndIdentityInfo
    }

}
