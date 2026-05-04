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
import SwiftUI
import WireDomain
import WireSyncEngine

final class JournalViewModel: ObservableObject {
    var sections: [DeveloperToolsViewModel.Section]

    private let userSession: ZMUserSession?

    init(userId: UUID, userSession: UserSession?, storage: UserDefaults = .shared()) {
        self.userSession = userSession as? ZMUserSession
        let journal = Journal(
            userID: userId,
            storage: storage
        )

        self.sections = [
            .init(
                header: "Main Keys",
                items:
                [
                    JournalKey.isConsumableNotificationsEnabled,
                    JournalKey.isConversationSyncRequired,
                    JournalKey.isCoreCryptoKeyMigrationToBytesRequired,
                    JournalKey.isCoreCryptoKeyMigrationToScopedKeyRequired,
                    JournalKey.isCoreCryptoKeyRotationRequired,
                    JournalKey.isInitialSyncRequired,
                    JournalKey.isSyncV2Enabled,
                    JournalKey.isBackendMLSEnabled,
                    JournalKey.isFederationMigrationRequired
                ].map {
                    DeveloperToolsViewModel.Item.text(.init(title: $0.name, value: journal[$0] == true ? "Yes" : "No"))
                }
            )
        ]

        sections.append(
            .init(
                header: "Broken MLS groups (\(journal[.brokenMLSGroupIDs].count))",
                items:
                groupNames(groupIDs: journal[.brokenMLSGroupIDs]).map { info in
                    DeveloperToolsViewModel.Item.text(.init(title: info.name, value: info.groupID))
                }
            )
        )
    }

    func groupNames(groupIDs: Set<String>) -> [(name: String, groupID: String)] {
        guard let context = userSession?.managedObjectContext else {
            return []
        }
        let mlsConversations = ZMConversation.fetchMLSConversations(in: context).filter {
            if let groupID = $0.mlsGroupID?.description {
                return groupIDs.contains(groupID)
            }
            return false
        }

        return mlsConversations.map { (name: $0.displayName ?? "N/A", groupID: $0.mlsGroupID?.description ?? "N/A") }
    }

    // MARK: - Events

    func handleEvent(_ event: DeveloperToolsViewModel.Event) {
        switch event {
        case .dismissButtonTapped:
            break

        case let .itemCopyRequested(.text(textItem)):
            UIPasteboard.general.string = textItem.value

        case let .itemTapped(.button(buttonItem)):
            buttonItem.action()

        default:
            break
        }
    }
}
