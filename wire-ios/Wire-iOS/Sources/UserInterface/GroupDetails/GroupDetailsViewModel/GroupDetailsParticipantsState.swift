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

struct GroupDetailsParticipantsState<Participant> {

    struct Section {
        let role: ConversationRole
        let participants: [Participant]
        let clipping: Clipping

        var clipSection: Bool {
            switch clipping {
            case .none:
                false
            case .showAll:
                true
            }
        }

        var maxParticipants: Int {
            switch clipping {
            case .none:
                .ConversationParticipants.maxNumberWithoutTruncation
            case let .showAll(maxParticipants, _):
                maxParticipants
            }
        }

        var maxDisplayedParticipants: Int {
            switch clipping {
            case .none:
                .ConversationParticipants.maxNumberOfDisplayed
            case let .showAll(_, maxDisplayedParticipants):
                maxDisplayedParticipants
            }
        }
    }

    enum Clipping {
        case none
        case showAll(maxParticipants: Int, maxDisplayedParticipants: Int)
    }

    let admins: [Participant]
    let members: [Participant]
    let sections: [Section]

    static func make(
        participants: [Participant],
        isAdmin: (Participant) -> Bool,
        maxNumberWithoutTruncation: Int = .ConversationParticipants.maxNumberWithoutTruncation,
        maxNumberOfDisplayed: Int = .ConversationParticipants.maxNumberOfDisplayed
    ) -> Self {
        let admins = participants.filter(isAdmin)
        let members = participants.filter { !isAdmin($0) }
        var sections = [Section]()

        guard !participants.isEmpty else {
            return Self(admins: admins, members: members, sections: sections)
        }

        if admins.count <= maxNumberWithoutTruncation || admins.isEmpty {
            if admins.count >= maxNumberOfDisplayed, participants.count > maxNumberWithoutTruncation {
                sections.append(.init(
                    role: .admin,
                    participants: admins,
                    clipping: .showAll(
                        maxParticipants: admins.count - 1,
                        maxDisplayedParticipants: maxNumberOfDisplayed
                    )
                ))
            } else {
                sections.append(.init(role: .admin, participants: admins, clipping: .none))

                if members.count <= maxNumberWithoutTruncation - admins.count {
                    if !members.isEmpty {
                        sections.append(.init(role: .member, participants: members, clipping: .none))
                    }
                } else {
                    let maxParticipants = maxNumberWithoutTruncation - admins.count
                    sections.append(.init(
                        role: .member,
                        participants: members,
                        clipping: .showAll(
                            maxParticipants: maxParticipants,
                            maxDisplayedParticipants: maxParticipants - 2
                        )
                    ))
                }
            }
        } else {
            sections.append(.init(
                role: .admin,
                participants: admins,
                clipping: .showAll(
                    maxParticipants: maxNumberWithoutTruncation,
                    maxDisplayedParticipants: maxNumberOfDisplayed
                )
            ))
        }

        return Self(admins: admins, members: members, sections: sections)
    }
}
