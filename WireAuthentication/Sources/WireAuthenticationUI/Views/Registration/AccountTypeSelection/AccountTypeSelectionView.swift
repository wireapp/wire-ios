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
        VStack(spacing: 24) {
            teamAccountView
            personalAccountView
        }
    }

    @ViewBuilder
    private var teamAccountView: some View {
        let background = RoundedRectangle(cornerRadius: 24, style: .circular)
            .stroke(.tint)
        VStack(spacing: 24) {
            teamAccountTitle
            teamAccountFeatures
            teamAccountButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var teamAccountTitle: some View {
        VStack(spacing: 8) {
            Text(L10n.AccountTypeSelector.OptionTeam.title)
                .font(.callout.bold())
                .foregroundStyle(.tint)
            Text(L10n.AccountTypeSelector.OptionTeam.subtitle)
        }
    }

    @ViewBuilder
    private var teamAccountFeatures: some View {
        VStack(spacing: 12) {
            Divider()
            teamAccountFeature(L10n.AccountTypeSelector.OptionTeam.feature0)
            Divider()
            teamAccountFeature(L10n.AccountTypeSelector.OptionTeam.feature1)
            Divider()
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func teamAccountFeature(_ content: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(.circleCheck)
                .foregroundStyle(ColorTheme.Base.positive.color)
                .padding(.vertical, 4)
            Text(content)
            Spacer()
        }
    }

    @ViewBuilder
    private var teamAccountButton: some View {
        Button(L10n.AccountTypeSelector.OptionTeam.button) {
            print("todo")
        }
        .wireButtonStyle(.primary)
        .bold()
    }

    @ViewBuilder
    private var personalAccountView: some View {
        Text(verbatim: "todo")
    }

}

private struct OptionView: View {

    var body: some View {
        EmptyView()
    }

}

#Preview {
    Spacer()
        .sheet(isPresented: .constant(true)) {
            AccountTypeSelectorView()
        }
}
