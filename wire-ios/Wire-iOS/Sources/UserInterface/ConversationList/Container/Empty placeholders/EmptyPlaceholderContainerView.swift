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
import WireDesign
import WireFoundation

final class EmptyPlaceholderContainerView: UIView {

    private(set) var placeholderView: EmptyPlaceholderView!
    private(set) var searchResultsView: EmptyConversationSearchResultsView!
    var connectWithPeopleAction: () -> Void
    var newConversationAction: () -> Void

    // MARK: - Init

    init(
        wireAccentColor: WireAccentColor,
        content: ConversationListViewController.EmptyPlaceholder,
        connectWithPeopleAction: @escaping () -> Void,
        newConversationAction: @escaping () -> Void
    ) {
        self.connectWithPeopleAction = connectWithPeopleAction
        self.newConversationAction = newConversationAction

        super.init(frame: .zero)

        self.searchResultsView = EmptyConversationSearchResultsView(
            iPadTargeted: isIPadRegular(),
            newConversationAction: { [weak self] in
                self?.newConversationAction()
            },
            connectWithPeopleAction: { [weak self] in
                self?.connectWithPeopleAction()
            }
        )

        let action = UIAction { [weak self] _ in
            self?.connectWithPeopleAction()
        }
        self.placeholderView = EmptyPlaceholderView(
            wireAccentColor: wireAccentColor,
            content: content,
            connectWithPeopleAction: action
        )

        backgroundColor = isIPadRegular() ? ColorTheme.Backgrounds.chatBackground : ColorTheme.Backgrounds
            .surfaceVariant

        setupConstraints()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func hideSearchResult(_ hidden: Bool) {
        searchResultsView.isHidden = hidden
        placeholderView.isHidden = !hidden
    }

    // MARK: - Setup

    private func setupConstraints() {
        [placeholderView, searchResultsView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
            NSLayoutConstraint.activate([
                $0.bottomAnchor.constraint(equalTo: bottomAnchor),
                $0.topAnchor.constraint(equalTo: topAnchor),
                $0.leadingAnchor.constraint(equalTo: leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }
    }

}
