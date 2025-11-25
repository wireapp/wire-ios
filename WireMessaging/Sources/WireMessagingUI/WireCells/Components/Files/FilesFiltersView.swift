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

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct FilesFiltersView: View {
    @StateObject package var viewModel: FilesFiltersViewModel
    @Environment(\.dismiss) var dismiss

    let id = UUID()

    package init(
        viewModel: @autoclosure @escaping () -> FilesFiltersViewModel
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.Backgrounds.background.color
                    .ignoresSafeArea(.all)

                ScrollView { tagsView }
            }
            .toolbar { toolbarContent }
            .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .alert(L10n.Localizable.General.failure, isPresented: $viewModel.showError) {
                Button(L10n.Localizable.General.confirm, role: .cancel) {}
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { applyButton } // floating button
            .overlay { if viewModel.isLoading { ProgressView() } }
            .task { await viewModel.fetch() }
        }
    }
}

// MARK: - Tags

private extension FilesFiltersView {
    var tagsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Strings.AllFiles.Filters.Tags.sectionTitle)
                .font(for: .body3)

            FlowLayout(spacing: 16, alignment: .leading) {
                ForEach(viewModel.presentedTags) { tag in
                    TagPill(
                        text: tag.name,
                        isSelected: tag.isSelected,
                        accentColor: viewModel.accentColorProvider()
                    )
                    .onTapGesture {
                        viewModel.selectTag(tag)
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.hasMore {
                Button {
                    withAnimation {
                        viewModel.showMore()
                    }
                } label: {
                    Text(Strings.AllFiles.Filters.Tags.loadMore)
                        .accessibilityIdentifier("loadMoreButton")
                }
            }

            Divider()

        }.padding()
    }

    private struct TagPill: View {
        let text: String
        let isSelected: Bool
        let accentColor: WireAccentColor

        var body: some View {
            Text(text)
                .foregroundStyle(
                    isSelected
                        ? ColorTheme.Base.primary(accentColor).color
                        : ColorTheme.Backgrounds.onSurface.color
                )
                .font(for: .h4)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    isSelected
                        ? ColorTheme.Base.primaryVariant(accentColor).color
                        : ColorTheme.Backgrounds.surface.color
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                                ? ColorTheme.Base.onPrimaryVariant.color
                                : .clear,
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
        }
    }
}

// MARK: - Toolbar

private extension FilesFiltersView {

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { clearAllButton }
        ToolbarItem(placement: .topBarTrailing) { closeButton }
    }

}

// MARK: - Buttons

private extension FilesFiltersView {
    var applyButton: some View {
        Button {
            Task {
                await viewModel.apply()
                dismiss()
            }
        } label: {
            Text(Strings.AllFiles.Filters.apply)
                .frame(minWidth: 0, maxWidth: .infinity)
                .accessibilityIdentifier("applyButton")
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .tint(Color(viewModel.accentColorProvider()))
        .font(for: .buttonBig)
        .padding()
    }

    var clearAllButton: some View {
        Button {
            Task { await viewModel.clearAll() }
        } label: {
            Text(Strings.AllFiles.Filters.clearAll)
                .accessibilityIdentifier("clearAllButton")
        }.disabled(viewModel.selectedTags.isEmpty)

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
        .accessibilityIdentifier("closeButton")
    }
}

#Preview {
    FilesFiltersView(viewModel: .preview())
}
