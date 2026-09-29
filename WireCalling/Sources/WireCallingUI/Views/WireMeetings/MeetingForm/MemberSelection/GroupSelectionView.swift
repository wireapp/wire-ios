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
import WireDesign

struct GroupSelectionView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule.Members

    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MemberSelectionViewModel
    @State private var selectedGroup: MeetingGroup?
    @State private var importTask: Task<Void, Never>?

    var body: some View {
        List {
            if viewModel.isSearchingGroups {
                HStack {
                    Spacer()
                    ProgressView(Strings.Groups.loading)
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if viewModel.hasGroupSearchError {
                ContentUnavailableView {
                    Label(Strings.Error.title, systemImage: "exclamationmark.magnifyingglass")
                } description: {
                    Text(Strings.Error.description)
                } actions: {
                    Button(Strings.Retry.button, action: viewModel.retryGroupSearch)
                        .wireButtonStyle(.tertiary)
                        .accessibilityIdentifier("meetingGroupSearchRetry")
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if viewModel.groupSearchResults.isEmpty {
                ContentUnavailableView(
                    Strings.Groups.emptyTitle,
                    systemImage: "person.3",
                    description: Text(Strings.Groups.emptyDescription)
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.groupSearchResults) { group in
                    Button {
                        importGroup(group)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: group.isChannel ? "number" : "person.3")
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.name)
                                    .font(.body)
                                Text(group.isChannel ? Strings.Groups.channel : Strings.Groups.group)
                                    .font(.subheadline)
                                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                            }
                            Spacer()
                            if viewModel.isImportingGroup, selectedGroup == group {
                                ProgressView()
                                    .accessibilityLabel(Strings.Groups.importing)
                            }
                        }
                    }
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                    .accessibilityLabel(group.name)
                    .accessibilityValue(group.isChannel ? Strings.Groups.channel : Strings.Groups.group)
                    .accessibilityIdentifier("meetingImportGroup-\(group.id)")
                }
            }
        }
        .disabled(viewModel.isImportingGroup)
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.background.color)
        .navigationTitle(Strings.Groups.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.groupSearchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Strings.Groups.searchPlaceholder
        )
        .onAppear(perform: viewModel.retryGroupSearch)
        .onDisappear {
            viewModel.cancelGroupSearch()
            importTask?.cancel()
        }
        .alert(Strings.Groups.importError, isPresented: $viewModel.hasGroupImportError) {
            Button(Strings.Retry.button) {
                if let selectedGroup { importGroup(selectedGroup) }
            }
            Button(Strings.Cancel.button, role: .cancel) {}
        } message: {
            Text(Strings.Error.description)
        }
    }

    private func importGroup(_ group: MeetingGroup) {
        selectedGroup = group
        importTask = Task {
            if await viewModel.importGroup(group.id), !Task.isCancelled {
                dismiss()
            }
        }
    }
}
