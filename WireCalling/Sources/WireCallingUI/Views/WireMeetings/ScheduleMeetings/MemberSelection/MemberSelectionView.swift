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
import WireCallingDomain
import WireFoundation

struct MemberSelectionView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule.Members

    @Environment(\.dismiss) private var dismiss
    @State private(set) var viewModel: MemberSelectionViewModel

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage, !viewModel.searchResults.isEmpty {
                    errorBanner(message: errorMessage)
                }

                Section {
                    if viewModel.isSelectedExpanded {
                        ForEach(viewModel.selectedMembers) { row(for: $0) }
                    }
                } header: {
                    sectionHeader(
                        title: "\(Strings.Selected.title) (\(viewModel.selectedMembers.count))",
                        isExpanded: $viewModel.isSelectedExpanded
                    )
                }

                Section {
                    if viewModel.isContactsExpanded {
                        contactsContent
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
                        .disabled(viewModel.selectedMembers.isEmpty)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var contactsContent: some View {
        if !viewModel.filteredUnselected.isEmpty {
            ForEach(viewModel.filteredUnselected) { row(for: $0) }
        } else if viewModel.isSearching {
            loadingPlaceholder
        } else if let errorMessage = viewModel.errorMessage {
            errorPlaceholder(message: errorMessage)
        } else {
            emptyPlaceholder
        }
    }

    private var loadingPlaceholder: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .padding(.vertical, 24)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var emptyPlaceholder: some View {
        HStack {
            Spacer()
            // TODO: localize, optionally differentiate "no results for query" vs "no contacts"
            Text("No contacts found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 20)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func errorPlaceholder(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(Strings.Retry.button) {
                viewModel.retrySearch()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func errorBanner(message: String) -> some View {
        Section {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.subheadline)
                Spacer()
                Button(Strings.Retry.button) {
                    viewModel.retrySearch()
                }
                .buttonStyle(.borderless)
            }
        }
    }

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

    private func row(for member: Member) -> some View {
        let isSelected = viewModel.isSelected(member)
        return Button {
            viewModel.toggleSelection(member)
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
                    Text(member.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    if !member.handle.isEmpty {
                        Text("@" + member.handle)
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

#Preview("success") {
    MemberSelectionView(viewModel: MemberSelectionViewModel(source: MockMemberSource()))
}

#Preview("empty") {
    MemberSelectionView(viewModel: MemberSelectionViewModel(source: MockMemberSource(members: [])))
}

#Preview("failure") {
    MemberSelectionView(
        viewModel: MemberSelectionViewModel(source: MockMemberSource(error: URLError(.badServerResponse)))
    )
}

// MARK: - Mock

struct MockMemberSource: MemberRepositoryProtocol {

    let result: Result<[Member], any Error>

    init(members: [Member] = .mock) {
        self.result = .success(members)
    }

    init(error: any Error) {
        self.result = .failure(error)
    }

    func search(query: String) async throws -> [Member] {
        switch result {
        case let .failure(error):
            throw error
        case let .success(members):
            guard !query.isEmpty else { return members }
            return members.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
    }
}

private extension [Member] {
    static var mock: Self {
        [
            .init(name: "Martin Koch-Johansen", handle: "username"),
            .init(name: "Olga Heaney", handle: "username"),
            .init(name: "Margarete Springer", handle: "username"),
            .init(name: "Lorenzo Schmeler", handle: ""),
            .init(name: "Jaqueline Olaho", handle: ""),
            .init(name: "Katie Armstrong", handle: "username"),
            .init(name: "Zachary Ratke", handle: "username"),
            .init(name: "Marco Weissnat", handle: "username"),
            .init(name: "Deborah Schoen", handle: "username")
        ]
    }
}

private extension Member {

    init(
        name: String,
        handle: String
    ) {
        self.init(
            qualifiedID: QualifiedID(id: UUID(), domain: ""),
            name: name,
            handle: handle
        )
    }

}

