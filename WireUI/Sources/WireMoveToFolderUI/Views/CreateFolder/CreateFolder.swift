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

public struct CreateFolder: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: CreateFolderViewModel
    private let conversationName: String
    private let onFolderCreated: (Folder) -> Void

    public init(
        viewModel: CreateFolderViewModel,
        conversationName: String,
        onFolderCreated: @escaping (Folder) -> Void
    ) {
        self.viewModel = viewModel
        self.conversationName = conversationName
        self.onFolderCreated = onFolderCreated
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
                .padding(.top, 16)

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
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray, lineWidth: 1)
                .frame(height: 48)
            TextField(
                localized("folder.creation.name.placeholder"),
                text: $viewModel.name
            )
            .padding(.horizontal, 8)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .accessibilityIdentifier("input.newfolder.name")
        }
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
                let createdFolder = try await viewModel.createFolder()
                dismiss()
                onFolderCreated(createdFolder)

            } catch {
                // TODO: [WPB-12173] Move WireLogger to a dedicated Swift Package Manager module for modular logging support
                assertionFailure("Failed to create and move folder: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreateFolder(
        viewModel: CreateFolderViewModel(
            useCase: PreviewCreateFolderUseCase()
        ),
        conversationName: "iOS Team",
        onFolderCreated: { _ in }
    )
}

private struct PreviewCreateFolderUseCase: CreateConversationFolderUseCaseProtocol {
    func invoke(name: String) async throws -> Folder {
        Folder(identifier: UUID(), name: name)
    }
}
