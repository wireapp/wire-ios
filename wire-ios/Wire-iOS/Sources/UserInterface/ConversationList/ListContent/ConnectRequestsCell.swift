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

import WireSyncEngine

// MARK: - SectionListCellType

protocol SectionListCellType: AnyObject {
    var sectionName: String? { get set }
    var obfuscatedSectionName: String? { get set }
    var cellIdentifier: String? { get set }
}

extension SectionListCellType {
    var identifier: String {
        [obfuscatedSectionName ?? sectionName, cellIdentifier]
            .compactMap { $0 }
            .joined(separator: " - ")
    }
}

// MARK: - ConnectRequestsCell

final class ConnectRequestsCell: UICollectionViewCell, SectionListCellType {
    var sectionName: String?
    var obfuscatedSectionName: String?
    var cellIdentifier: String?

    let itemView = ConversationListItemView()

    private var hasCreatedInitialConstraints = false
    private var currentConnectionRequestsCount = 0
    private var conversationListObserverToken: Any?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConnectRequestsCell()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConnectRequestsCell() {
        clipsToBounds = true
        addSubview(itemView)
        updateAppearance()

        if let userSession = ZMUserSession.shared() {
            conversationListObserverToken = ConversationListChangeInfo.add(
                observer: self,
                for: ConversationList.pendingConnectionConversations(inUserSession: userSession),
                userSession: userSession
            )
        }

        setNeedsUpdateConstraints()
    }

    override var accessibilityIdentifier: String? {
        get {
            identifier
        }
        set {
            // no op
        }
    }

    override func updateConstraints() {
        if !hasCreatedInitialConstraints {
            hasCreatedInitialConstraints = true
            itemView.translatesAutoresizingMaskIntoConstraints = false
            itemView.fitIn(view: self)
        }
        super.updateConstraints()
    }

    private func updateItemViewSelected() {
        itemView.selected = isSelected || isHighlighted
    }

    override var isSelected: Bool {
        didSet {
            if isIPadRegular() {
                updateItemViewSelected()
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            if isIPadRegular() {
                updateItemViewSelected()
            } else {
                itemView.selected = isHighlighted
            }
        }
    }

    private
    func updateAppearance() {
        guard let userSession = ZMUserSession.shared() else { return }

        let connectionRequests: ConversationList = .pendingConnectionConversations(inUserSession: userSession)
        let users = connectionRequests.items.compactMap(\.oneOnOneUser)
        if users.count != currentConnectionRequestsCount {
            currentConnectionRequestsCount = users.count
            let title = L10n.Localizable.List.ConnectRequest.peopleWaiting(users.count)
            itemView.configure(with: NSAttributedString(string: title), subtitle: NSAttributedString(), users: users)
        }
    }
}

// MARK: ZMConversationListObserver

extension ConnectRequestsCell: ZMConversationListObserver {
    func conversationListDidChange(_: ConversationListChangeInfo) {
        updateAppearance()
    }
}
