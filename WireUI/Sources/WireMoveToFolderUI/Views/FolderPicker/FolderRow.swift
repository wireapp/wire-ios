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

struct FolderRow: View {
    let folder: Folder
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(folder.name)
                    .font(for: isSelected ? .h3 : .body1)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark").foregroundColor(Color.primary)
                }
            }
        }
        .accessibilityIdentifier("row.folder.\(folder.identifier?.uuidString ?? "")")
        .accessibilityLabel(folder.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    FolderRow(
        folder: Folder(identifier: nil, name: "Friends"),
        isSelected: true
    ) {}
}
