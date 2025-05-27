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

struct AccountTypeSelectorView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                scrollViewContent
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(L10n.AccountTypeSelector.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetCloseButton {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var scrollViewContent: some View {
        VStack {
            Text(L10n.AccountTypeSelector.title)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
              RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.blue)
            )
//            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding()
    }

}

#Preview {
    Spacer()
        .sheet(isPresented: .constant(true)) {
            AccountTypeSelectorView()
        }
}
