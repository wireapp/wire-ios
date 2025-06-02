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
import WireReusableUIComponents

struct CreatePersonalAccountView: View {

    @StateObject private var viewModel: CreatePersonalAccountViewModel
    @Environment(\.dismiss) private var dismiss

    private typealias Strings = L10n.Localizable.CreatePersonalAccount
    private typealias Labels = L10n.Accessibility.CreatePersonalAccount

    package init(viewModel: CreatePersonalAccountViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                scrollViewContent
            }
            .sheet(isPresented: $viewModel.isCreateTeamAccountPresented, onDismiss: {
                dismiss()
            }, content: {
                if let teamAccountCreationLink = viewModel.teamAccountCreationLink {
                    SafariBrowserView(url: teamAccountCreationLink)
                        .ignoresSafeArea()
                }
            })
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetCloseButton {
                        dismiss()
                    }
                    .accessibilityLabel(Labels.Close.label)
                }
            }
        }
    }

    @ViewBuilder private var scrollViewContent: some View {
        VStack(spacing: 24) {
            dataUsageAgreementView
            continueButton
            teamAccountCreationView
        }
    }

    @ViewBuilder private var dataUsageAgreementView: some View {
        Checkbox(
            isChecked: $viewModel.enableAnalyticsSharing,
            title: .formattedMarkdown(
                key: "create_personal_account.share_data_usage",
                bundle: .module,
                viewModel.privacyPolicyURL.absoluteString
            )
        )
    }

    @ViewBuilder private var continueButton: some View {
        Button(action: {
            Task {
                await viewModel.submitCredentials()
            }
        }, label: {
            Text(Strings.continue)
                .lineLimit(nil)
        })
        .wireButtonStyle(.primary)
        .bold()
        .disabled(!viewModel.canSubmitCredentials)
    }

    @ViewBuilder private var teamAccountCreationView: some View {}

}

// TODO: move to ReusableUIComponents
struct Checkbox: View {
    @Binding var isChecked: Bool

    private let title: AttributedString

    init(isChecked: Binding<Bool>, title: AttributedString) {
        self._isChecked = isChecked
        self.title = title
    }

    init(isChecked: Binding<Bool>, title: String) {
        self._isChecked = isChecked
        self.title = AttributedString(title)
    }

    var body: some View {
        HStack {
            Button(action: {
                isChecked.toggle()
            }, label: {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24))
            })
            .buttonStyle(.plain)
            .foregroundStyle(isChecked ? ColorTheme.Checkbox.selected.color : ColorTheme.Checkbox.enabled.color)
            Text(title)
                .wireTextStyle(.subline1)
        }
    }
}
