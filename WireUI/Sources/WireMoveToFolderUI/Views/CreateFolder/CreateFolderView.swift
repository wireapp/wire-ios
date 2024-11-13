//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

public struct CreateFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: CreateFolderViewModel

    public init(viewModel: CreateFolderViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        TextField(
                            String(
                                localized: "folder.creation.name.placeholder",
                                table: "Localizable",
                                bundle: .module
                            ),
                            text: $viewModel.name
                        )
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("input.newfolder.name")
                    }

                    Text("Maximum 64 characters")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                }
                .scrollContentBackground(.hidden)
                .background(Color.viewBackground)
            }
            .background(Color.viewBackground)
            .navigationTitle(Text("folder.picker.title", tableName: "Localizable", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        String(
                            localized: "folder.creation.name.button.create",
                            table: "Localizable",
                            bundle: .module
                        )
                    ) {
                        Task {
                            do {
                                _ = try await viewModel.createFolder()
                                dismiss()
                            } catch {
                                // TODO: Handle error
                            }
                        }
                    }
                    .disabled(!viewModel.canCreate)
                    .accessibilityIdentifier("button.newfolder.create")
                }
            }
        }
    }
}

#Preview {
    CreateFolderView(
        viewModel: CreateFolderViewModel(
            useCase: PreviewCreateFolderUseCase()
        )
    )
}

private struct PreviewCreateFolderUseCase: CreateConversationFolderUseCaseProtocol {
    func invoke(name: String) async throws -> Folder {
        return Folder(identifier: UUID(), name: name)
    }
}
