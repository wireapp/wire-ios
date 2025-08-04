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
import UIKit
import WireDesign

final class EmptyConversationSearchResultsView: UIView {

    var newConversationAction: () -> Void
    var connectWithPeopleAction: (() -> Void)?
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var hostingViewController: UIHostingController<EmptyView>!

    init(
        iPadTargeted: Bool,
        newConversationAction: @escaping () -> Void,
        connectWithPeopleAction: (() -> Void)?
    ) {
        self.newConversationAction = newConversationAction
        self.connectWithPeopleAction = connectWithPeopleAction

        super.init(frame: .zero)

        self.hostingViewController = UIHostingController(rootView: EmptyView(
            iPadTargeted: iPadTargeted,
            newConversationAction: { [weak self] in
                self?.newConversationAction()
            },
            connectWithPeopleAction: { [weak self] in
                self?.connectWithPeopleAction?()
            }
        ))

        addSubview(hostingViewController.view)
        hostingViewController.sizingOptions = .intrinsicContentSize
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        let stackView = hostingViewController!.view!
        stackView.backgroundColor = .clear
        NSLayoutConstraint.activate([

            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            stackView.leadingAnchor.constraint(
                greaterThanOrEqualToSystemSpacingAfter: safeAreaLayoutGuide.leadingAnchor,
                multiplier: 1
            ),
            stackView.topAnchor.constraint(
                greaterThanOrEqualToSystemSpacingBelow: safeAreaLayoutGuide.topAnchor,
                multiplier: 1
            ),
            safeAreaLayoutGuide.trailingAnchor.constraint(
                greaterThanOrEqualToSystemSpacingAfter: stackView.trailingAnchor,
                multiplier: 1
            ),
            safeAreaLayoutGuide.bottomAnchor.constraint(
                greaterThanOrEqualToSystemSpacingBelow: stackView.bottomAnchor,
                multiplier: 1
            ),

            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 272)
        ])

    }
}

private struct EmptyView: View {
    var iPadTargeted: Bool
    var newConversationAction: () -> Void
    var connectWithPeopleAction: () -> Void

    var body: some View {
        if iPadTargeted {
            TabletEmptyView(
                newConversationAction: newConversationAction,
                connectWithPeopleAction: connectWithPeopleAction
            )
        } else {
            PhoneEmptyView(newConversationAction: newConversationAction)
        }
    }
}

private struct PhoneEmptyView: View {
    var newConversationAction: () -> Void

    var body: some View {
        VStack {
            Text(L10n.Localizable.ConversationList.EmptyPlaceholder.Search.Subheadline.phone)
                .font(.textStyle(.body1))
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(nil)

            Button(action: {
                newConversationAction()
            }, label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color(ColorTheme.Base.primary)))

                    Text(L10n.Localizable.ConversationList.EmptyPlaceholder.Search.Button.phone)
                        .font(.textStyle(.body1))
                        .foregroundStyle(Color(ColorTheme.Base.primary))
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)

            })
            .accessibilityIdentifier("new-conversation.button")
            .background(Capsule().fill(Color.viewBackground))
        }
    }
}

private struct TabletEmptyView: View {
    var newConversationAction: () -> Void
    var connectWithPeopleAction: () -> Void

    var body: some View {
        VStack {
            Text(L10n.Localizable.ConversationList.EmptyPlaceholder.Search.Subheadline.ipad)
                .font(.textStyle(.body1))
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(nil)

            CapsuleButton(
                title: L10n.Localizable.ConversationList.EmptyPlaceholder.Search.Button.ipad,
                accessibilityIdentifier: "new-conversation.button",
                action: newConversationAction
            )

            Text(L10n.Localizable.General.or)
                .font(.textStyle(.body1))
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            CapsuleButton(
                title: L10n.Localizable.ConversationList.EmptyPlaceholder.Search.connectButton,
                accessibilityIdentifier: "connect.button",
                action: connectWithPeopleAction
            )

        }
    }
}

private struct CapsuleButton: View {
    var title: String
    var accessibilityIdentifier: String
    var action: () -> Void

    var body: some View {
        Button(action: action, label: {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color(ColorTheme.Base.primary)))

                Text(title)
                    .font(.textStyle(.body1))
                    .foregroundStyle(Color(ColorTheme.Base.primary))
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)

        })
        .accessibilityIdentifier(accessibilityIdentifier)
        .background(Capsule().fill(Color.viewBackground))
    }
}
