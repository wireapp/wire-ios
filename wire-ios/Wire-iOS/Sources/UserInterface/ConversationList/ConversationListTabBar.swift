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

import UIKit
import WireSyncEngine
import WireCommonComponents

enum TabBarItemType: Int, CaseIterable {

    typealias BottomBar = L10n.Localizable.ConversationList.BottomBar
    typealias TabBar = L10n.Accessibility.TabBar

    case startUI, list, archive

    var order: Int {
        return rawValue
    }

    var icon: UIImage {
        switch self {
        case .startUI:
            return .init(resource: .contactsOutline)
        case .list:
            return .init(resource: .conversationsOutline)
        case .archive:
            return .init(resource: .archiveOutline)
        }
    }

    var selectedIcon: UIImage {
        switch self {
        case .startUI:
            return .init(resource: .contactsFilled)
        case .list:
            return .init(resource: .conversationsFilled)
        case .archive:
            return .init(resource: .archiveFilled)
        }
    }

    var title: String {
        switch self {
        case .startUI:
            BottomBar.Contacts.title
        case .list:
            BottomBar.Conversations.title
        case .archive:
            BottomBar.Archived.title
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .startUI:
            return "bottomBarPlusButton"
        case .list:
            return "bottomBarRecentListButton"
        case .archive:
            return "bottomBarArchivedButton"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .startUI:
            return TabBar.Contacts.description
        case .list:
            return TabBar.Conversations.description
        case .archive:
            return TabBar.Archived.description
        }
    }

    var accessibilityHint: String? {
        switch self {
        case .startUI:
            TabBar.Contacts.hint
        case .archive:
            TabBar.Archived.hint
        case .list:
            nil
        }
    }

}

final class ConversationListTabBar: UITabBar { // ?

    private let startTab = UITabBarItem(type: .startUI)
    private let listTab = UITabBarItem(type: .list)
    private let archivedTab = UITabBarItem(type: .archive)

    var showArchived: Bool = false {
        didSet {
            var tabs: [UITabBarItem] = [startTab, listTab]
            if showArchived {
                tabs.append(archivedTab)
            }
            setItems(tabs, animated: true)
        }
    }

    var selectedTab: TabBarItemType? {
        didSet {
            if let selectedTab = selectedTab {
                switch selectedTab {
                case .archive, .startUI:
                    return
                case .list:
                    selectedItem = listTab
                }
            }
        }
    }

    // MARK: - Init
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        setupLargeContentViewer()

        barTintColor = SemanticColors.View.backgroundConversationList
        isTranslucent = false
        items = [startTab, listTab, archivedTab]
    }

    private func setupLargeContentViewer() {
        let interaction = UILargeContentViewerInteraction(delegate: self)
        addInteraction(interaction)

        showsLargeContentViewer = true
        scalesLargeContentImage = true
    }

}

// MARK: - ConversationListViewModelRestorationDelegate

extension ConversationListTabBar: ConversationListViewModelRestorationDelegate {

    func listViewModelDidRestore(_ model: ConversationListViewModel) {
        selectedTab = .list
    }
}

// MARK: - UILargeContentViewerInteractionDelegate

extension ConversationListTabBar: UILargeContentViewerInteractionDelegate {

    func largeContentViewerInteraction(_: UILargeContentViewerInteraction, itemAt: CGPoint) -> UILargeContentViewerItem? {
        setupLargeContentViewer(at: itemAt)

        return self
    }

    private func setupLargeContentViewer(at location: CGPoint) {
        guard let tabBarItem = tabBarItem(at: location) else {
            return
        }
        largeContentTitle = tabBarItem.title
        largeContentImage = tabBarItem.image
    }

}

extension UITabBarItem {

    convenience init(type: TabBarItemType) {
        self.init(title: type.title,
                  image: type.icon.resize(for: .medium).withRenderingMode(.alwaysTemplate),
                  selectedImage: type.selectedIcon.resize(for: .medium).withRenderingMode(.alwaysTemplate))

        tag = type.order

        /// Setup accessibility properties
        accessibilityIdentifier = type.accessibilityIdentifier
        accessibilityLabel = type.accessibilityLabel
        accessibilityHint = type.accessibilityHint
    }

}

private extension UITabBar {

    func tabBarItem(at location: CGPoint) -> UITabBarItem? {
        guard let itemsCount = items?.count else {
            return nil
        }

        let itemWidth: CGFloat = (frame.width / CGFloat(itemsCount))

        switch location.x {
        case 0 ..< itemWidth:
            return UITabBarItem(type: .startUI)
        case itemWidth ..< (2 * itemWidth):
            return UITabBarItem(type: .list)
        default:
            return UITabBarItem(type: .archive)
        }
    }
}
