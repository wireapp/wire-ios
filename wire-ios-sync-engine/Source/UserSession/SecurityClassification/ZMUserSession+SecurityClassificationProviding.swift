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

extension ZMUserSession: SecurityClassificationProviding {
    public func classification(
        users: [UserType],
        conversationDomain: String?
    ) -> SecurityClassification? {
        guard isSelfClassified else { return .none }

        if let conversationDomain,
           classifiedDomainsFeature.config.domains.contains(conversationDomain) == false {
            return .notClassified
        }

        let isClassified = users.allSatisfy { user in
            classification(user: user) == .classified
        }

        return isClassified ? .classified : .notClassified
    }

    func classification(user: UserType) -> SecurityClassification? {
        guard isSelfClassified else {
            return .none
        }
        guard let otherDomain = domain(for: user), !user.isTemporaryUser else {
            return .notClassified
        }

        return classifiedDomainsFeature.config.domains.contains(otherDomain)
            ? .classified
            : .notClassified
    }

    var isSelfClassified: Bool {
        classifiedDomainsFeature.status == .enabled && providedSelfUser.domain != nil
    }

    // If other user does not have a domain the conversation will be marked as unclassified
    // We've had a different behaviour on Android & Web on column-1
    // We could not save domain to the database as of now, because of how other features depend on it
    // If federation is disabled we know that the user is from local backend, so we can fallback to local domain and
    // check if it is classified
    private func domain(for user: UserType) -> String? {
        guard BackendInfo.isFederationEnabled else {
            return user.domain ?? BackendInfo.domain
        }
        return user.domain
    }
}
