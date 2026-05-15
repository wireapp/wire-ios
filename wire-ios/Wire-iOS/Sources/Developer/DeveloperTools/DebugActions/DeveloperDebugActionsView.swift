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

struct DeveloperDebugActionsView: View {

    @ObservedObject var viewModel: DeveloperDebugActionsViewModel
    @State var userInput: String = ""

    var body: some View {
        List(viewModel.debugItems) { debugItem in
            switch debugItem {
            case let .button(buttonItem):
                Button(hapticFeedbackStyle: .success, action: buttonItem.action) {
                    Text(buttonItem.title)
                }
            case let .toggle(toggleItem):
                Toggle(isOn: toggleItem.isOn) {
                    Text(toggleItem.title)
                        .foregroundColor(.accentColor)
                }.disabled(!toggleItem.enabled)
            }
        }
        .sheet(item: $viewModel.mlsGroupSearchItem, content: mlsGroupSearchView)
        .sheet(isPresented: $viewModel.isKMPActionsPresented) {
            kmpActionsView
        }
        .sheet(isPresented: $viewModel.isAppVersionInputPresented) {
            appVersionInputView
        }
        .alert(
            viewModel.kmpLoginProbeReport?.title ?? "",
            isPresented: Binding(
                get: { viewModel.kmpLoginProbeReport != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.kmpLoginProbeReport = nil
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    viewModel.kmpLoginProbeReport = nil
                }
            },
            message: {
                if let report = viewModel.kmpLoginProbeReport {
                    Text(report.details)
                }
            }
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    func mlsGroupSearchView(_ item: MLSGroupSearchItem) -> some View {
        List {
            Section("Conversations with MLS Group ID") {
                HStack {
                    TextField("Enter MLS Group ID", text: $userInput)
                        .onSubmit(submitUserInput)
                    Button("Search", action: submitUserInput)
                        .disabled(userInput.isEmpty)
                }
            }
            switch item {
            case let .result(results, term):
                if results.isEmpty, !term.isEmpty {
                    Section {
                        Text("Nothing found")
                    }
                } else {
                    ForEach(results, id: \.id) { result in
                        Section {
                            TextItemCell(title: "Name:", value: result.name) {
                                UIPasteboard.general.string = result.name
                            }
                            TextItemCell(title: "Conversation id:", value: result.id) {
                                UIPasteboard.general.string = result.id
                            }
                            TextItemCell(title: "MLS Group id:", value: result.groupID?.description ?? "-") {
                                UIPasteboard.general.string = result.groupID?.description ?? "-"
                            }
                        }
                    }
                }
            }
        }
    }

    private func submitUserInput() {
        Task {
            await viewModel.findConversations(with: userInput.trim())
        }
    }

    @ViewBuilder private var appVersionInputView: some View {
        TextField(
            "Enter app version, like 1.2.3",
            text: $userInput
        )
        .textFieldStyle(.roundedBorder)
        .onSubmit {
            viewModel.setLastCompletedAppVersionMigration(version: userInput)
        }
        .padding()
        .presentationDetents([.height(200)])
    }

    // TODO: Remove this sheet with the temporary WireIosShared login probe.
    @ViewBuilder private var kmpActionsView: some View {
        NavigationStack {
            List {
                Button("Run login email VM probe") {
                    viewModel.runKMPLoginIdentifierProbe()
                }

                Button("Run login email VM probe with credentials") {
                    viewModel.requestKMPLoginIdentifierProbeInput()
                }
            }
            .navigationTitle("KMP actions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.isKMPActionsPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Previews

#Preview {
    DeveloperDebugActionsView(viewModel: DeveloperDebugActionsViewModel(userSession: nil, selfClient: nil))
}
