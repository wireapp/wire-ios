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
import WireLocators
import WireMessagingDomain
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct FileVersioningView: View, Identifiable {
    @StateObject package var viewModel: FileVersioningViewModel
    @Environment(\.dismiss) private var dismiss

    let id = UUID()

    init(viewModel: @autoclosure @escaping () -> FileVersioningViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.Backgrounds.background.color
                    .ignoresSafeArea(.all)

                Group {
                    switch viewModel.state {
                    case .loading:
                        ProgressView()
                            .progressViewStyle(.circular)
                    case .received:
                        Form { sections }
                            .scrollContentBackground(.hidden)
                            .background(ColorTheme.Backgrounds.background.color)
                    case .restoringVersion:
                        VStack {
                            RestoreVersionProgressView()
                                .padding(.bottom, 25)

                            Text(Strings.FilesVersioning.restoringVersion)
                                .foregroundStyle(ColorTheme.Backgrounds.onBackground.color)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
            .quickLookPreview($viewModel.viewingURL) // TODO: [WPB-19395] Temporary implementation
            .refreshable { await viewModel.fetch() }
            .alert(
                item: $viewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: {
                    ForEach($0.actionsButtons, id: \.id) { action in
                        Button(action.title, role: action.role, action: { Task { await action.handler() } })
                    }
                }
            )
        }.task { viewModel.startPolling() }
    }

}

private struct RestoreVersionProgressView: View {
    @State private var rotate = false

    let dotCount = 20
    let dotSize: CGFloat = 3
    let radius: CGFloat = 20
    let animationDuration: Double = 2.0

    var body: some View {
        ZStack {
            ForEach(0 ..< dotCount, id: \.self) { index in
                Circle()
                    .frame(width: dotSize, height: dotSize)
                    .foregroundColor(ColorTheme.Base.secondaryText.color)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(index) / Double(dotCount) * 360))
            }
        }
        .rotationEffect(.degrees(rotate ? 360 : 0))
        .animation(.linear(duration: animationDuration).repeatForever(autoreverses: false), value: rotate)
        .onAppear {
            rotate = true
        }
    }
}

// MARK: - Toolbar

private extension FileVersioningView {

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack {
                Text(Strings.FilesVersioning.navigationTitle)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                    .font(.headline)
                Text(viewModel.name)
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
            }
        }

        ToolbarItem(placement: .topBarTrailing) { closeButton }
    }

    var closeButton: some View {
        Button(
            action: { dismiss() },
            label: {
                Image(.close)
                    .foregroundStyle(SemanticColors.Icon.foregroundDefaultBlack.color)
                    .frame(width: 44, height: 44, alignment: .trailing)
            }
        )
        .accessibilityLabel(Accessibility.Files.close)
        .accessibilityIdentifier(Locators.FileVersioningPage.closeButton.rawValue)
    }
}

// MARK: - Sections & Rows

extension FileVersioningView {

    var sections: some View {
        ForEach(
            Array(viewModel.state.versions.enumerated()),
            id: \.element,
            content: section
        )
    }

    func section(index: Int, version: FileVersioningViewModel.VersionModel) -> some View {
        Section(version.header) {
            ForEach(Array(version.items.enumerated()), id: \.element) { itemIndex, _ in
                itemRow(
                    sectionIndex: index,
                    itemIndex: itemIndex
                )
            }
        }
    }

    func itemRow(sectionIndex: Int, itemIndex: Int) -> some View {
        FileVersionItemView(
            viewModel: viewModel.itemViewModel(
                sectionIndex: sectionIndex,
                itemIndex: itemIndex
            )
        )
    }
}

#Preview {
    FileVersioningView(viewModel: .preview())
}
