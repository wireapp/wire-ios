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

public struct CreateFolder: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: CreateFolderViewModel
    private let conversationName: String 

    public init(
        viewModel: CreateFolderViewModel,
        conversationName: String
    ) {
        self.viewModel = viewModel
        self.conversationName = conversationName
    }

    public var body: some View {
        NavigationStack {
            content
                .background(Color.viewBackground)
                .navigationTitle(localized("folder.picker.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { createButton }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            descriptionText
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 4) {
                folderNameField
                footerText
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private var descriptionText: some View {
        Text(
            String(
                format: NSLocalizedString(
                    "folder.creation.name.header",
                    tableName: "Localizable",
                    bundle: .module,
                    comment: ""
                ),
                conversationName
            )
        )
        .foregroundStyle(.secondary)
    }

    private var folderNameField: some View {
        TextField(
            localized("folder.creation.name.placeholder"),
            text: $viewModel.name
        )
        .textFieldStyle(.plain)
        .autocorrectionDisabled()
        .accessibilityIdentifier("input.newfolder.name")
    }

    private var footerText: some View {
        Text(localized("folder.creation.name.footer"))
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private var createButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(localized("folder.creation.name.button.create")) {
                createFolder()
            }
            .disabled(!viewModel.canCreate)
            .accessibilityIdentifier("button.newfolder.create")
        }
    }

    private func localized(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }

    private func createFolder() {
        Task {
            do {
                _ = try await viewModel.createFolder()
                dismiss()
            } catch {
                // TODO: Handle error
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreateFolder(
        viewModel: CreateFolderViewModel(
            useCase: PreviewCreateFolderUseCase()
        ), conversationName: "iOS Team"
    )
}

private struct PreviewCreateFolderUseCase: CreateConversationFolderUseCaseProtocol {
    func invoke(name: String) async throws -> Folder {
        return Folder(identifier: UUID(), name: name)
    }
}
