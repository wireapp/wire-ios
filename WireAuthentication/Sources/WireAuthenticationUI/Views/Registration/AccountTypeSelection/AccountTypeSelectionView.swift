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

    // MARK: -

    @ViewBuilder
    private var teamAccountView: some View {
        let background = RoundedRectangle(cornerRadius: 24, style: .circular)
            .stroke(ColorTheme.Base.primary.color)
        VStack(spacing: 24) {
            teamAccountTitles
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
    private var teamAccountTitles: some View {
        VStack(spacing: 8) {
            Text(L10n.AccountTypeSelector.OptionTeam.title)
                .font(.callout.bold())
                .foregroundStyle(ColorTheme.Base.primary.color)
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
            print("[WPB-17453]") // TODO: [WPB-17453] implement flow
        }
        .wireButtonStyle(.primary)
        .bold()
    }

    // MARK: -

    @ViewBuilder
    private var personalAccountView: some View {
        let background = RoundedRectangle(cornerRadius: 24, style: .circular)
            .stroke(ColorTheme.Strokes.outline.color)
        VStack(spacing: 24) {
            personalAccountTitles
            personalAccountFeatures
            personalAccountButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var personalAccountTitles: some View {
        VStack(spacing: 8) {
            Text(L10n.AccountTypeSelector.OptionPersonal.title)
                .font(.callout.bold())
                .foregroundStyle(ColorTheme.Base.primary.color)
            Text(L10n.AccountTypeSelector.OptionPersonal.subtitle)
        }
    }

    @ViewBuilder
    private var personalAccountFeatures: some View {
        VStack(spacing: 12) {
            Divider()
            personalAccountFeature(L10n.AccountTypeSelector.OptionPersonal.feature0)
            Divider()
            personalAccountFeature(L10n.AccountTypeSelector.OptionPersonal.feature1)
            Divider()
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func personalAccountFeature(_ content: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(.circleCheck)
                .foregroundStyle(ColorTheme.Base.positive.color)
                .padding(.vertical, 4)
            Text(content)
            Spacer()
        }
    }

    @ViewBuilder
    private var personalAccountButton: some View {
        Button(L10n.AccountTypeSelector.OptionPersonal.button) {
            print("[WPB-17453]") // TODO: [WPB-17453] implement flow
        }
        .wireButtonStyle(.secondary)
        .bold()
    }

}

#Preview {
    Spacer()
        .sheet(isPresented: .constant(true)) {
            AccountTypeSelectorView()
        }
}
