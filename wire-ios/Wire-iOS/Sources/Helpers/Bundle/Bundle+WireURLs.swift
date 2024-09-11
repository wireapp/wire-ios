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

/// This struct contains various URLs used in the app. All links are defined in the `url.json` configuration file.
///
/// IMPORTANT: If you change or add a new property to this struct, you will also need to update the corresponding
/// link with the same key in the existing URL configuration files.
/// Failure to do so may cause the application to crash.
struct WireURLs: Codable {
    /// Link to the app on the App store.
    let appOnItunes: URL

    /// Link to the main support page.
    let support: URL

    /// Link to the help desk support page.
    let searchSupport: URL

    /// Link to the app's homepage.
    let website: URL

    /// Shown when the user tries to create an account with an email that is already in use.
    /// Links to support page explaining issue and what can be done.
    let emailAlreadyInUse: URL

    /// Link to an article explaining why a user should verify conversations using fingerprints.
    let whyToVerifyFingerprintArticle: URL

    /// Link to an article explaining how to manually verify conversations using fingerprints.
    let howToVerifyFingerprintArticle: URL

    /// Link to the privacy policy page.
    let privacyPolicy: URL

    /// Link to app's homepage for legal information, e.g terms of use and data processing addendum.
    let legal: URL

    /// Link to the license information page.
    let licenseInformation: URL

    /// Link to the password reset page.
    let passwordReset: URL

    /// Link to the support page where the user can submit a support request for various issues.
    let askSupportArticle: URL

    /// Link to the support page where a user can report an abuse issue.
    let reportAbuse: URL

    /// Link to an article explaining the various features of Wire.
    let wireEnterpriseInfo: URL

    /// Link to an article explaining legal hold.
    let legalHoldInfo: URL

    /// Link to an article explaining how to create, share, and revoke a group conversation link.
    let guestLinksInfo: URL

    /// Shown when a user tries to send a message or create a group with users from different backends when one of the
    /// backends is not reachable.
    /// Links to a support page that explains the issue when one of the backend is offline.
    let unreachableBackendInfo: URL

    /// Links to a support page explaining what Federation is.
    let federationInfo: URL

    /// Link to the article about Messaging Layer Security (MLS).
    /// Shown in various places (e.g. system messages, warnings, error messages).
    let mlsInfo: URL

    /// Link to the article about end-to-end identity.
    /// Shown in various places (e.g. system messages, warnings, error messages).
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
