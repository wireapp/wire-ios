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

import Foundation

struct DigitalSignatureVerificationViewModel {

    struct DisplayState: Equatable {
        let doneButtonTitle: String
        let doneButtonAccessibilityIdentifier: String
    }

    enum Route {
        case verificationSucceeded
        case verificationFailed(DigitalSignatureVerificationError)
        case none
    }

    let url: URL
    let displayState = DisplayState(
        doneButtonTitle: L10n.Localizable.General.done,
        doneButtonAccessibilityIdentifier: "DoneButton"
    )

    var request: URLRequest {
        URLRequest(url: url)
    }

    init(url: URL) {
        self.url = url
    }

    func route(for url: URL) -> Route {
        let urlComponents = URLComponents(string: url.absoluteString)
        let postCode = urlComponents?.queryItems?
            .first(where: { $0.name == "postCode" })

        guard let postCodeValue = postCode?.value else {
            return .none
        }

        switch postCodeValue {
        case "sas-success":
            return .verificationSucceeded
        case "sas-error-authentication-failed":
            return .verificationFailed(.authenticationFailed)
        default:
            return .verificationFailed(.otherError)
        }
    }
}
