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

struct DomainRegistrationConfigurationV10: Decodable, ToAPIModelConvertible {

    struct Backend: Decodable, Sendable {
        let configURLString: String
        let webAppURLString: String?

        enum CodingKeys: String, CodingKey {
            case configURLString = "config_url"
            case webAppURLString = "webapp_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case domainRedirect = "domain_redirect"
        case isCloudAccountAlreadyRegistered = "due_to_existing_account"
        case ssoCodeString = "sso_code"
        case backend
    }

    public let backend: Backend?
    public let domainRedirect: DomainRedirectV8
    public let isCloudAccountAlreadyRegistered: Bool?
    public let ssoCodeString: String?

    func toAPIModel() -> DomainRegistrationConfiguration {
        DomainRegistrationConfiguration(
            backendURLString: backend?.configURLString,
            domainRedirect: domainRedirect.toAPIModel(),
            isCloudAccountAlreadyRegistered: isCloudAccountAlreadyRegistered,
            ssoCodeString: ssoCodeString
        )
    }

}
