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

/// This struct contains various URLs used in the app.
///
/// IMPORTANT: If you change or add a new property to this struct, you will also need to update the corresponding
/// link with the same key in the existing URL configuration files.
/// Failure to do so may cause the application to crash.
struct WireURLs: Codable {

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
    let passwordReset: URL
    let askSupportArticle: URL
    let reportAbuse: URL
    let wireEnterpriseInfo: URL
    let legalHoldInfo: URL
    let guestLinksInfo: URL
    let unreachableBackendInfo: URL
    let federationInfo: URL
    let mlsInfo: URL
    let endToEndIdentityInfo: URL

    static var shared: WireURLs = {
        do {
            return try WireURLs(forResource: "url", withExtension: "json")
        } catch {
            fatalError("\(error)")
        }
    }()

    private init(forResource resource: String, withExtension fileExtension: String) throws {
        guard let fileURL = Bundle.fileURL(for: resource, with: fileExtension) else {
            throw WireURLsError.fileNotFound
        }

        self = try fileURL.decode(WireURLs.self)
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
        case passwordReset
        case askSupportArticle
        case reportAbuse
        case wireEnterpriseInfo
        case legalHoldInfo
        case guestLinksInfo
        case unreachableBackendInfo
        case federationInfo
        case mlsInfo
        case endToEndIdentityInfo
    }

    enum WireURLsError: Error {
        case fileNotFound
    }

}
