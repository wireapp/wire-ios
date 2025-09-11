//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
    
    init(userId: UUID) {
        let journal = Journal(
            userID: userId,
            storage: UserDefaults.shared()
        )
        
        sections = [
            .init(header: "Main Keys", items:
                [JournalKey.isConsumableNotificationsEnabled,
                 JournalKey.isConversationSyncRequired,
                 JournalKey.isCoreCryptoKeyMigrationRequired,
                 JournalKey.isInitialSyncRequired,
                 JournalKey.isSyncV2Enabled].map {
                     DeveloperToolsViewModel.Item.text(.init(title: $0.name, value: journal[$0] == true ? "Yes" : "No"))
                 }
            )//,
//            .init(header: "Broken MLS groups (\(journal[.brokenMLSGroupIDs].count))", items:
//                groupNames(groupIDs: journal[.brokenMLSGroupIDs]).map({ groupID in
//                    DeveloperToolsViewModel.Item.text(.init(title: groupID, value: "name"))
//                })
//            )
        ]
        
    
    }

//    func groupNames(groupIDs: Set<String>) -> [(name: String, groupID: String)] {
//        guard let context = ZMUserSession.shared()?.managedObjectContext else {
//            return []
//        }
//        
//        for groupID in groupIDs {
//            ZMConversation.fetchConversationsWithMLSGroupStatus(mlsGroupStatus: <#T##MLSGroupStatus#>, in: <#T##NSManagedObjectContext#>)
//        }
//        
//        
//    }
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
