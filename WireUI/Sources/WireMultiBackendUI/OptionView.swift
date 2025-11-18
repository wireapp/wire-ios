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
import WireDesign
import WireLocators

public  struct Option: Identifiable {

    public let id = UUID()

    public enum Icon {
        case plus
        case manage
    }

    public enum ActionImage {
        case manage
    }

    let icon: Icon
    let text: String
    let actionImage: ActionImage?
    let action: () -> Void
    let accessibilityIdentifier: String?

    public static func manageTeamOption(action: @escaping () -> Void) -> Option {
        Option(
            icon: .manage,
            text: L10n.Localizable.ManageTeam.title,
            actionImage: .manage,
            action: action,
            accessibilityIdentifier: Locators.UserProfilePage.manageTeamButton.rawValue
        )
    }

    public static func addAccountOption(action: @escaping () -> Void) -> Option {
        Option(
            icon: .plus,
            text: L10n.Localizable.AddAccount.title,
            actionImage: nil,
            action: action,
            accessibilityIdentifier: Locators.UserProfilePage.addAcccountOrTeamButton.rawValue
        )
    }

    public init(
        icon: Icon,
        text: String,
        actionImage: ActionImage?,
        action: @escaping () -> Void,
        accessibilityIdentifier: String? = nil
    ) {
        self.icon = icon
        self.text = text
        self.actionImage = actionImage
        self.action = action
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

struct OptionView: View {

    let option: Option

    var body: some View {
        HStack(spacing: 19) {
            HStack {
                image(option.icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 16, height: 16)
                Spacer()
            }.frame(width: 28, height: 28)
                .padding(.leading, 3)

            Text(option.text)
                .font(for: .body2)
                .bold()
                .foregroundStyle(Color(SemanticColors.Label.textDefault))

            Spacer()
            switch option.actionImage {
            case .manage:
                Image(.externalLink)
            case .none:
                EmptyView()
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(option.text)
        .accessibilityIdentifier(option.accessibilityIdentifier ?? "")
        .onTapGesture {
            option.action()
        }
    }

    func image(_ icon: Option.Icon) -> Image {
        switch option.icon {
        case .plus:
            Image(.plus)
        case .manage:
            Image(.manageTeam)
        }
    }

}

#Preview {
    List {
        OptionView(option: .manageTeamOption(action: {}))
        OptionView(option: .addAccountOption(action: {}))
    }
}
