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

public extension ZMConversation {

    @objc var isFavorite: Bool {
        get {
            labels.any { $0.kind == .favorite }
        }
        set {
            guard let managedObjectContext else { return }

            let favoriteLabel = Label.fetchFavoriteLabel(in: managedObjectContext)

            if newValue {
                assignLabel(favoriteLabel)
            } else {
                removeLabel(favoriteLabel)
            }
        }

    }

    @objc var folder: LabelType? {
        labels.first(where: { $0.kind == .folder })
    }

    @objc
    func moveToFolder(_ folder: LabelType) {
        guard let label = folder as? Label, !label.isZombieObject, label.kind == .folder else { return }

        removeFromFolder()
        assignLabel(label)
    }

    @objc
    func removeFromFolder() {
        let existingFolders = labels.filter { $0.kind == .folder }
        labels.subtract(existingFolders)

        for emptyFolder in existingFolders.filter(\.conversations.isEmpty) {
            emptyFolder.markForDeletion()
        }
    }

    internal func assignLabel(_ label: Label) {
        labels.insert(label)
    }

    internal func removeLabel(_ label: Label) {
        labels.remove(label)
    }

}
