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
    
    @State private var testLinkData: String = "?"
    
    init(fileItem: FilesViewItem, useCases: ViewModel.UseCases) {
        _viewModel = .init(wrappedValue: .init(fileItem: fileItem, useCases: useCases))
    }
    
    var body: some View {
        NavigationStack {
            content()
                .navigationTitle(Text(Strings.ShareLink.title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent()
                }
                .sheet(item: $viewModel.sheetNavigation) { navigationItem in
                    switch navigationItem {
                    case .password:
                        ShareLinkPasswordView(
                            password: "The password, if it exists. Otherwise nil",
                            onSave: { password in
                                //TODO: apply the new password. If it is nil, then the password was disabled.
                            }
                        )
                    case .expiration:
                        Text("TODO: Expiration view")
                    }
                }
                .background {
                    ColorTheme.Backgrounds.background.color
                        .ignoresSafeArea(edges: .all)
                }
                .tint(ColorTheme.Base.primary(wireAccentColor).color)
                .task {
                    if let linkIdString = viewModel.fileItem.publicLinkId, let linkId = UUID(uuidString: linkIdString) {
                        let linkData = try? await viewModel.useCases.getLinkData.invoke(linkId: linkId)
                        testLinkData = linkData?.url.absoluteString ?? "-"
                    }
                }
        }
    }
    
    @ViewBuilder private func content() -> some View {
        ScrollView {
            VStack {
                Text("link id: \(viewModel.fileItem.publicLinkId ?? "-")")
                
                Text("url: \(testLinkData)")
                
                Button {
                    viewModel.sheetNavigation = .password
                } label: {
                    Text("Password (dummy)")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.sheetNavigation = .expiration
                } label: {
                    Text("Expiration (dummy)")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
    
    @ToolbarContentBuilder private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Text(L10n.Localizable.General.cancel)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                //TODO: ...
            } label: {
                Text(L10n.Localizable.General.done)
                    .bold()
            }
        }
    }
}

#Preview {
    let item = FilesViewItem(
        id: UUID(),
        kind: .file,
        name: "some_file.pdf",
        filePath: "some/path",
        ownedBy: nil,
        modifiedAt: nil,
        icon: .document,
        tags: [],
        publicLinkId: UUID().uuidString,
    )
    
    let mockAPI = {
        let mockAPI = MockNodesAPIProtocol()
        mockAPI.getPublicLinkLinkUUID_MockMethod = { _ in
            WireCellsPublicLink(
                uuid: UUID(),
                url: URL(string: "https://example.com")!,
                password: "r1ckr0ll",
                expirationDate: "1234567890",
            )
        }
        return mockAPI
    }()
    
    let useCases: ShareLinkView.ViewModel.UseCases = .init(
        getLinkData: WireCellsGetPublicLinkDataUseCase(nodesAPI: mockAPI),
    )
    
    ShareLinkView(
        fileItem: item,
        useCases: useCases,
    )
}
