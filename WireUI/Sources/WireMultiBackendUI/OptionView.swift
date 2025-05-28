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

struct Option: Identifiable {
    
    let id = UUID()

    enum Icon {
        case plus
        case manage
    }
    
    enum ActionImage {
        case manage
    }
    
    let icon: Icon
    let text: String
    let actionImage: ActionImage?
}

struct OptionView: View {
    
    let option: Option
    
    var body: some View {
        HStack {
            Label {
                Text(option.text)
                    .font(FontSpec.bodyTwoSemibold.swiftUIFont)
                    .foregroundStyle(Color(SemanticColors.Label.textDefault))

            } icon: {
                switch option.icon {
                case .plus:
                    Image(.plus)
                case .manage:
                    Image(.manageTeam)
                }
            }

            Spacer()
            switch option.actionImage {
            case .manage:
                Image(.externalLink)
            case .none:
                EmptyView()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Handle external link
        }
    }
}

#Preview {
    OptionView(option: Option(icon: .manage, text: "Manage Team & Billing", actionImage: .manage))
}
