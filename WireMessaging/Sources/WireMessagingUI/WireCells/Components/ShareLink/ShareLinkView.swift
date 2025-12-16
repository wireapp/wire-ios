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
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct ShareLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.wireAccentColor) private var wireAccentColor

    @StateObject private var viewModel: ViewModel

    init(fileItem: FilesViewItem, useCases: ViewModel.UseCases) {
        _viewModel = .init(wrappedValue: .init(fileItem: fileItem, useCases: useCases))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 24) {

                        mainToggleSection()

                        if let linkID = viewModel.linkID {
                            linkSettingsSection(linkID: linkID)
                        }
                    }
                    .padding()
                    .padding(.bottom, 80) // Space for the bottom button
                }

                shareLinkButton()
            }
            .onAppear { Task { await viewModel.loadIfNeeded() } }
            .background(ColorTheme.Backgrounds.background.color.ignoresSafeArea())
            .navigationTitle(Strings.ShareLink.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent()
            }
            .sheet(item: $viewModel.sheetNavigation) { navigationItem in
                switch navigationItem {
                case .password:
                    ShareLinkPasswordView(
                        password: "viewModel.password", // FIXME:
                        onSave: { newPassword in
                            "viewModel.password = newPassword" // FIXME:
                        }
                    )
                case let .expiration(linkID):
                    viewModel.makeExpirationDatePickerView(linkID: linkID)
                }
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private func mainToggleSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.ShareLink.description)
                .font(for: .subline1)
                .foregroundStyle(ColorTheme.Base.secondaryText.color)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(
                Strings.ShareLink.createLinkToogle,
                isOn: Binding(get: {
                    viewModel.isLinkToggleOn
                }, set: { isEnabled in
                    Task { await viewModel.togglePublicLink(isEnabled: isEnabled) }
                })
            )
                .font(for: .body1)
                .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(ColorTheme.Backgrounds.surface.color)
                }
                .tint(wireAccentColor.color)
                .disabled(!viewModel.isLinkToggleEnabled)
        }
    }

    @ViewBuilder
    private func linkSettingsSection(linkID: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.ShareLink.LinkSection.title)
                .font(for: .subline2)
                .foregroundStyle(ColorTheme.Base.secondaryText.color)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 0) {
                settingsRow(
                    title: Strings.ShareLink.LinkSection.passwordTitle,
                    description: Strings.ShareLink.LinkSection.passwordDescription,
                    status: viewModel.passwordStatusText,
                    action: { viewModel.sheetNavigation = .password },
                )

                Spacer().frame(height: 16)

                settingsRow(
                    title: Strings.ShareLink.LinkSection.expirationTitle,
                    description: Strings.ShareLink.LinkSection.expirationDescription,
                    status: viewModel.expirationStatusText,
                    action: { viewModel.sheetNavigation = .expiration(linkID: linkID) }
                )
            }
        }
    }

    @ViewBuilder
    private func settingsRow(
        title: String,
        description: String,
        status: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading) {
            Button(action: action) {
                HStack {
                    Text(title)
                        .font(for: .body1)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                    Spacer()

                    HStack(spacing: 4) {
                        Text(status)
                            .font(for: .body1)
                            .foregroundStyle(ColorTheme.Base.secondaryText.color)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .contentShape(Rectangle()) // Makes the whole row tapable
            }
            .buttonStyle(.plain)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(ColorTheme.Backgrounds.surface.color)
            }

            Text(description)
                .font(for: .subline1)
                .foregroundStyle(ColorTheme.Base.secondaryText.color)
                .padding(.leading, 4)
        }
    }

    @ViewBuilder
    private func shareLinkButton() -> some View {
        VStack {
            Button {
                viewModel.copyLink()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Link")
                        .fontWeight(.semibold)
                }
                .font(for: .body1)
                .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(ColorTheme.Backgrounds.surface.color)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(ColorTheme.Backgrounds.background.color.opacity(0.9)) // Slight fade behind button area
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Text(L10n.Localizable.General.cancel)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
//                viewModel.saveLink()
                dismiss()
            } label: {
                Text(L10n.Localizable.General.done)
                    .bold()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let item = FilesViewItem(
        id: UUID(),
        eTag: "eTag",
        kind: .file,
        name: "some_file.pdf",
        filePath: "some/path",
        ownedBy: nil,
        modifiedAt: nil,
        icon: .document,
        tags: [],
        isEditable: false,
        publicLinkId: UUID().uuidString,
    )

    let mockAPI = {
        let mockAPI = MockNodesAPIProtocol()
        mockAPI.getPublicLinkLinkID_MockMethod = { _ in
            WireCellsPublicLink(
                linkID: "aaaa",
                url: URL(string: "https://example.com")!,
                requiresPassword: true,
                expirationDate: Date().addingTimeInterval(3600),
            )
        }
        return mockAPI
    }()

    let useCases: ShareLinkView.ViewModel.UseCases = .init(
        getLinkData: WireCellsGetPublicLinkDataUseCase(nodesAPI: mockAPI),
        createPublicLink: WireCellsCreatePublicLinkUseCase(nodesAPI: mockAPI),
        deletePublicLink: WireCellsDeletePublicLinkUseCase(nodesAPI: mockAPI),
        updatePublicLinkExpiration: WireCellsUpdatePublicLinkExpirationUseCase(nodesAPI: mockAPI),
        updatePublicLinkPassword: WireCellsUpdatePublicLinkPasswordUseCase(nodesAPI: mockAPI)
    )

    ShareLinkView(
        fileItem: item,
        useCases: useCases,
    )
}
