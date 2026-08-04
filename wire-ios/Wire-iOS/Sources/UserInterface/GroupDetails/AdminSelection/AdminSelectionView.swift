//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireSyncEngine

struct AdminSelectionView: View {

    @StateObject var viewModel: AdminSelectionViewModel
    @Environment(\.dismiss) private var dismiss

    private var backgroundColor: Color {
        ColorTheme.Backgrounds.background.color
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.promotionState == .failed },
            set: { if !$0 { viewModel.promotionState = .idle } }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AdminSearchBar(text: $viewModel.searchQuery)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                List {
                    Section {
                        Text(L10n.Localizable.AdminSelection.infoBanner)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .listRowSeparator(.hidden)
                            .listRowBackground(backgroundColor)
                    }
                    Section {
                        ForEach(viewModel.filteredCandidates, id: \.remoteIdentifier) { user in
                            AdminCandidateRow(
                                user: user,
                                userSession: viewModel.userSession,
                                isSelected: viewModel.selectedUser?.remoteIdentifier == user.remoteIdentifier
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedUser = user
                            }
                            .listRowBackground(backgroundColor)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
            }
            .background(backgroundColor)
            .navigationTitle(L10n.Localizable.AdminSelection.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Localizable.General.cancel) {
                        dismiss()
                    }
                    .accessibilityIdentifier(Locators.AdminSelectionPage.cancelButton.rawValue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Localizable.AdminSelection.promote) {
                        if let user = viewModel.selectedUser {
                            Task { await viewModel.promote(user: user) }
                        }
                    }
                    .disabled(!viewModel.canPromote)
                    .accessibilityIdentifier(Locators.AdminSelectionPage.promoteButton.rawValue)
                }
            }
            .onChange(of: viewModel.promotionState) { _, state in
                if state == .succeeded { dismiss() }
            }
            .alert(L10n.Localizable.AdminSelection.promotionError, isPresented: isShowingError) {
                Button(L10n.Localizable.General.ok) {
                    // empty block since we only dismiss the alert
                }
            }
        }
    }
}

private struct AdminSearchBar: View {

    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(L10n.Localizable.Peoplepicker.searchPlaceholder, text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(L10n.Accessibility.AdminSelection.SearchBar.ClearButton.description)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ColorTheme.Backgrounds.surfaceVariant.color,
            in: RoundedRectangle(cornerRadius: 10)
        )
    }
}

private struct AdminCandidateRow: View {

    let user: UserType
    let userSession: UserSession
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            UserImageViewRepresentable(user: user, userSession: userSession, size: .small)
                .frame(
                    width: CGFloat(UserImageView.Size.small.rawValue),
                    height: CGFloat(UserImageView.Size.small.rawValue)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.name ?? "")
                    .font(.body)
                    .fontWeight(.semibold)

                if let handle = user.handle {
                    Text("@\(handle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            CheckmarkIcon(isSelected: isSelected)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(Locators.AdminSelectionPage.userCell.rawValue)
        .accessibilityHint(L10n.Accessibility.AdminSelection.CandidateRow.hint)
        .accessibilityAddTraits([isSelected ? .isSelected : []])
    }
}

private struct CheckmarkIcon: View {

    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentColor : ColorTheme.Backgrounds.surface.color)
                .overlay(
                    Circle().strokeBorder(
                        isSelected ? Color.clear : ColorTheme.Strokes.outline.color,
                        lineWidth: 2
                    )
                )
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTheme.Base.onPrimary.color)
            }
        }
        .frame(width: 24, height: 24)
    }
}
