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

struct EmptyState: View {
    let image: Image
    let description: Text
    let linkText: Text
    let url: URL

    var body: some View {
        Group {
            VStack {
                image
                    .font(.system(size: 40))
                    .foregroundStyle(Color.secondaryText)
                    .padding(.bottom, 16)

                description
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)

                Link(destination: url) {
                    linkText
                        .multilineTextAlignment(.center)
                        .underline()
                }
            }
            .font(.textStyle(.body1))
            .foregroundStyle(Color.primaryText)
            .frame(maxWidth: 272)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyState(
        image: Image(systemName: "folder"),
        description: Text(verbatim: "Add your conversations to folders to stay organized."),
        linkText: Text(verbatim: "How to add a conversation to a folder"),
        url: URL(string: "http://example.com")!
    )
}
