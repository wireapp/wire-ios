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

import Foundation

@objcMembers
public class FolderList: NSObject {
    // MARK: Lifecycle

    public init(labels: [Label]) {
        self.backingList = labels.sorted(by: FolderList.comparator)
    }

    // MARK: Public

    @objc(insertLabel:)
    public func insert(label: Label) {
        guard let sortDescriptors = Label.defaultSortDescriptors(), !sortDescriptors.isEmpty else {
            return
        }

        let index = backingList.firstIndex(where: { FolderList.comparator(label, $0) }) ?? backingList.count

        backingList.insert(label, at: index)
    }

    @objc(resortLabel:)
    public func resort(label: Label) {
        remove(label: label)
        insert(label: label)
    }

    @objc(removeLabel:)
    public func remove(label: Label) {
        backingList.removeAll(where: { $0 == label })
    }

    // MARK: Internal

    // TODO: jacob turn into struct and make generic
    var backingList: [Label]

    // MARK: Private

    private static var comparator: (Label, Label) -> Bool {
        guard let sortDescriptors = Label.defaultSortDescriptors(), !sortDescriptors.isEmpty else {
            fatal("Missing sort descriptors")
        }

        return { (lhs: Any, rhs: Any) -> Bool in
            for sortDesriptor in sortDescriptors {
                let result = sortDesriptor.compare(lhs, to: rhs)

                if result != .orderedSame {
                    return result == .orderedAscending
                }
            }

            return true
        }
    }
}
