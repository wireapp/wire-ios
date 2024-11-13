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

import SwiftUI
import UIKit
import WireDesign

final class EmptyConversationSearchResultsView: UIView {

    var newConversationAction: () -> Void

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var hostingViewController: UIHostingController<EmptyView>!

    init(newConversationAction: @escaping () -> Void) {
        self.newConversationAction = newConversationAction

        super.init(frame: .zero)

        self.hostingViewController = UIHostingController(rootView: EmptyView(newConversationAction: { [weak self] in
            self?.newConversationAction()
        }))

        self.addSubview(hostingViewController.view)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        let stackView = hostingViewController!.view!
        stackView.backgroundColor = .clear
        NSLayoutConstraint.activate([

            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),

            stackView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: self.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            stackView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: self.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            self.safeAreaLayoutGuide.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 1),
            self.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: stackView.bottomAnchor, multiplier: 1),

            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 272)
        ])

    }
}

private struct EmptyView: View {
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
