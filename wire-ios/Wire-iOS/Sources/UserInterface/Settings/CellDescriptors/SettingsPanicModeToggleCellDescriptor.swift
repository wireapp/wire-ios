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

import UIKit
import WireDataModel
import WireSyncEngine

final class SettingsPanicModeToggleCellDescriptor: SettingsCellDescriptorType {

    static let cellType: SettingsTableCellProtocol.Type = SettingsToggleCell.self

    let title: String = "Panic Mode"
    let identifier: String? = "PanicModeSwitch"
    var visible: Bool = true
    weak var group: (any SettingsGroupCellDescriptorType)?

    private weak var userSession: UserSession?

    private static let panicModeKey = "com.wire.panicMode.enabled"
    private static let promotedConversationsKey = "com.wire.panicMode.promotedConversationIDs"

    private var isPanicModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.panicModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.panicModeKey) }
    }

    private var promotedConversationIDs: [String] {
        get { UserDefaults.standard.stringArray(forKey: Self.promotedConversationsKey) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: Self.promotedConversationsKey) }
    }

    init(userSession: UserSession) {
        self.userSession = userSession
    }

    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = title
        if let toggleCell = cell as? SettingsToggleCell {
            toggleCell.switchView.isOn = isPanicModeEnabled
            toggleCell.switchView.accessibilityLabel = identifier
            toggleCell.accessibilityTraits = .toggleButton
        }
    }

    func select(_ value: SettingsPropertyValue, sender: UIView) {
        guard let boolValue = value.value() as? Bool ?? (value.value() as? NSNumber)?.boolValue else {
            return
        }

        isPanicModeEnabled = boolValue

        if boolValue {
            upgradeSensitiveConversations()
        } else {
            revertPromotedConversations()
        }
    }

    // MARK: - Conversation Updates

    private func upgradeSensitiveConversations() {
        userSession?.enqueue { [weak self, weak userSession] in
            guard let context = (userSession as? ZMUserSession)?.managedObjectContext else { return }
            let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
            fetchRequest.predicate = NSPredicate(
                format: "confidentialityLevel == %d",
                ConfidentialityLevel.sensitive.rawValue
            )

            guard let conversations = try? context.fetch(fetchRequest) else { return }
            var promotedIDs: [String] = []
            for conversation in conversations {
                conversation.confidentialityLevel = .highlySensitive
                if let id = conversation.remoteIdentifier?.uuidString {
                    promotedIDs.append(id)
                }
            }
            DispatchQueue.main.async {
                self?.promotedConversationIDs = promotedIDs
            }
        }
    }

    private func revertPromotedConversations() {
        let idsToRevert = promotedConversationIDs
        guard !idsToRevert.isEmpty else { return }

        userSession?.enqueue { [weak self, weak userSession] in
            guard let context = (userSession as? ZMUserSession)?.managedObjectContext else { return }
            let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
            fetchRequest.predicate = NSPredicate(
                format: "confidentialityLevel == %d",
                ConfidentialityLevel.highlySensitive.rawValue
            )

            guard let conversations = try? context.fetch(fetchRequest) else { return }
            let idsSet = Set(idsToRevert)
            for conversation in conversations where idsSet.contains(conversation.remoteIdentifier?.uuidString ?? "") {
                conversation.confidentialityLevel = .sensitive
            }
            DispatchQueue.main.async {
                self?.promotedConversationIDs = []
            }
        }
    }
}
