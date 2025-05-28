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

struct AccountUIModel: Identifiable {
    let id = UUID()

    let name: String
    let handle: String
    let teamName: String?
    let backendName: String?
    let imageName: String? // name of asset in Assets.xcassets
}

struct AccountView: View {
    
    let account: AccountUIModel
    
    var body: some View {
        HStack {
            Image(account.imageName ?? "")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                
                Text(account.name)
                    .font(FontSpec.bodyTwoSemibold.swiftUIFont)
                    .foregroundStyle(Color(SemanticColors.Label.textDefault))
                
                DotSeparatedTextView(
                    items: [
                        account.handle,
                        account.teamName,
                        account.backendName
                    ].compactMap { $0 }
                )
                
            }
            .padding(.vertical, 4)
        }
    }
}

struct DotSeparatedTextView: View {
    
    let items: [String]

    var body: some View {
        let combinedText = items.joined(separator: " • ")
        Text(combinedText)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .font(Font.textStyle(.subline1))
            .foregroundStyle(Color(SemanticColors.Label.baseSecondaryText))
    }
}

#Preview {
    AccountView(
        account: AccountUIModel(
            name: "Deniz Agha",
            handle: "@username",
            teamName: "team name",
            backendName: "backend name",
            imageName: nil
        )
    )
}
