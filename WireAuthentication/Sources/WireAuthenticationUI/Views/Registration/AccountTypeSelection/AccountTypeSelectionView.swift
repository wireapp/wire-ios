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
            teamAccountView
            personalAccountView
        }
    }

    @ViewBuilder
    private var teamAccountView: some View {
        let background = RoundedRectangle(cornerRadius: 24, style: .circular)
            .stroke(.tint)
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(L10n.AccountTypeSelector.OptionTeam.title)
                    .font(.callout.bold())
                Text(L10n.AccountTypeSelector.OptionTeam.subtitle)
            }
            VStack {
                Divider()
                Text(verbatim: "abcd")
                Divider()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .padding()
    }

    @ViewBuilder
    private var personalAccountView: some View {
    }

}

#Preview {
    Spacer()
        .sheet(isPresented: .constant(true)) {
            AccountTypeSelectorView()
        }
}
