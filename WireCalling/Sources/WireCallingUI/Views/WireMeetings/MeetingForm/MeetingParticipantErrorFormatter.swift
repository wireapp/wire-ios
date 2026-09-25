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
import WireCallingDomain

enum MeetingParticipantErrorFormatter {

    private typealias Strings = L10n.Localizable

    static func message(
        participants: [MeetingMember],
        reasons: [QualifiedID: MeetingParticipantFailureReason]
    ) -> String {
        guard let first = participants.first else { return "" }
        if participants.count == 1 {
            let name = escaped(first.name)
            switch reasons[first.qualifiedID] {
            case .nonFederatingBackends:
                return Strings.failedToAddParticipantSingularNonFederatingBackends(name)
            case let .offlineBackend(domain):
                return Strings.failedToAddParticipantSingularOfflineBackend(name, escaped(domain))
            case nil:
                return Strings.failedToAddParticipantSingularOfflineForTooLong(name)
            }
        }

        let groups = Dictionary(grouping: participants) { reasons[$0.qualifiedID] }
        let details = groups.values.sorted { $0[0].name < $1[0].name }.map { members in
            detail(members: members, reason: reasons[members[0].qualifiedID])
        }
        return ([Strings.failedToAddParticipantsPlural(participants.count)] + details).joined(separator: "\n\n")
    }

    static func attributed(_ message: String) -> AttributedString {
        (try? AttributedString(markdown: message, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(message)
    }

    private static func detail(members: [MeetingMember], reason: MeetingParticipantFailureReason?) -> String {
        let names = members.map { escaped($0.name) }
        if names.count == 1 {
            switch reason {
            case .nonFederatingBackends:
                return Strings.failedToAddParticipantsSingularDetailsNonFederatingBackends(names[0])
            case let .offlineBackend(domain):
                return Strings.failedToAddParticipantsSingularDetailsOfflineBackend(names[0], escaped(domain))
            case nil:
                return Strings.failedToAddParticipantsSingularDetailsOfflineForTooLong(names[0])
            }
        }

        let precedingNames = names.dropLast().joined(separator: ", ")
        let lastName = names[names.count - 1]
        switch reason {
        case .nonFederatingBackends:
            return Strings.failedToAddParticipantsPluralDetailsNonFederatingBackends(precedingNames, lastName)
        case let .offlineBackend(domain):
            return Strings.failedToAddParticipantsPluralDetailsOfflineBackend(precedingNames, lastName, escaped(domain))
        case nil:
            return Strings.failedToAddParticipantsPluralDetailsOfflineForTooLong(precedingNames, lastName)
        }
    }

    private static func escaped(_ value: String) -> String {
        value.map { "\\`*_{}[]()#+-.!>|~".contains($0) ? "\\\($0)" : String($0) }.joined()
    }
}
