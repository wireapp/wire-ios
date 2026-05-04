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

enum DomainRedirectV8: String, Decodable, Sendable {

    case locked
    case sso
    case backend
    case noRegistration = "no-registration"
    case preAuthorized = "pre-authorized"
    case none

    func toAPIModel() -> DomainRedirect {
        switch self {
        case .locked:
            .locked
        case .sso:
            .sso
        case .backend:
            .backend
        case .noRegistration:
            .noRegistration
        case .preAuthorized:
            .preAuthorized
        case .none:
            .none
        }
    }

}
