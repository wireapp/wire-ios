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

struct ParticipantSelectionView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule.Participants

    @Environment(\.dismiss) private var dismiss
    @State private(set) var viewModel: ParticipantSelectionViewModel

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.selectedParticipants.isEmpty {
                    Section {
                        if viewModel.isSelectedExpanded {
                            ForEach(viewModel.selectedParticipants) { row(for: $0) }
                        }
                    } header: {
                        sectionHeader(
                            title: "\(Strings.Selected.title) (\(viewModel.selectedIDs.count))",
                            isExpanded: $viewModel.isSelectedExpanded
                        )
                    }
                }

                Section {
                    if viewModel.isContactsExpanded {
                        ForEach(viewModel.filteredUnselected) { row(for: $0) }
                    }
                } header: {
                    sectionHeader(
                        title: Strings.Contacts.title,
                        isExpanded: $viewModel.isContactsExpanded
                    )
                }
            }
            .listStyle(.plain)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Strings.Search.Field.placeholder
            )
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.Cancel.button, role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.Select.button) { dismiss() }
                        .disabled(viewModel.selectedIDs.isEmpty)
                }
            }
        }
    }

    // MARK: - Subviews

    private func sectionHeader(title: String, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation { isExpanded.wrappedValue.toggle() }
        } label: {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : -90))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .buttonStyle(.plain)
        .textCase(nil)
    }

    private func row(for participant: ParticipantSelectionViewModel.Participant) -> some View {
        let isSelected = viewModel.selectedIDs.contains(participant.id)
        return Button {
            viewModel.toggleSelection(participant.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .hidden()
                    .overlay {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.tertiary)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let username = participant.username {
                        Text("@" + username)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ParticipantSelectionView(viewModel: ParticipantSelectionViewModel())
}
