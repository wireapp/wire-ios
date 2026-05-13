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
import WireSettingsUI

final class SettingsTableViewModel {

    enum SelectionAction {
        case showSettingsContent(SettingsTopLevelMenuItem)
        case select(SettingsCellDescriptorType)
    }

    private let group: SettingsInternalGroupCellDescriptorType
    private var sections: [SettingsSectionDescriptorType]

    var title: String {
        group.title
    }

    var accessibilityBackButtonText: String {
        group.accessibilityBackButtonText
    }

    var allCellDescriptors: [SettingsCellDescriptorType] {
        group.items.flatMap(\.cellDescriptors)
    }

    init(group: SettingsInternalGroupCellDescriptorType) {
        self.group = group
        self.sections = group.visibleItems
    }

    func refresh() {
        sections = group.visibleItems
    }

    func numberOfSections() -> Int {
        sections.count
    }

    func numberOfRows(in sectionIndex: Int) -> Int {
        section(at: sectionIndex)?.visibleCellDescriptors.count ?? 0
    }

    func cellDescriptor(at indexPath: IndexPath) -> SettingsCellDescriptorType? {
        guard let section = section(at: indexPath.section),
              section.visibleCellDescriptors.indices.contains(indexPath.row) else {
            return nil
        }

        return section.visibleCellDescriptors[indexPath.row]
    }

    func headerTitle(for sectionIndex: Int) -> String? {
        section(at: sectionIndex)?.header
    }

    func footerTitle(for sectionIndex: Int) -> String? {
        section(at: sectionIndex)?.footer
    }

    func copyText(for indexPath: IndexPath) -> String? {
        cellDescriptor(at: indexPath)?.copiableText
    }

    func selectionAction(at indexPath: IndexPath) -> SelectionAction? {
        guard let cellDescriptor = cellDescriptor(at: indexPath) else {
            return nil
        }

        if let content = cellDescriptor.settingsTopLevelMenuItem {
            return .showSettingsContent(content)
        }

        return .select(cellDescriptor)
    }

    private func section(at index: Int) -> SettingsSectionDescriptorType? {
        guard sections.indices.contains(index) else {
            return nil
        }

        return sections[index]
    }
}
