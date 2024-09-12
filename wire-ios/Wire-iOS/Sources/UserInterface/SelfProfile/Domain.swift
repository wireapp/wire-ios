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

/// Enum representing the type of domain.
///
/// - publicDomain: Represents a public domain, like "wire.com".
/// - privateDomain: Represents a private domain (any domain other than public).
/// - unknown: Represents an unknown or undefined domain.
enum DomainType {

    case publicDomain
    case privateDomain
    case unknown

}

extension String {

    var domainType: DomainType {
        switch self {
        case "wire.com", "staging.zinfra.io":
            return .publicDomain
        default:
            return .privateDomain
        }
    }
}
