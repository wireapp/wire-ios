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

struct FilesFilterView: View {
    @StateObject package var viewModel: FilesFiltersViewModel
    @Environment(\.dismiss) var dismiss

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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(Strings.AllFiles.Filters.Tags.sectionTitle)
                            .wireTextStyle(.h2)
                        
                        FlowLayout(spacing: 16, alignment: .leading) {
                            ForEach(viewModel.presentedTags, id: \.self) { tag in
                                TagPill(
                                    text: tag.name,
                                    isSelected: tag.isSelected
                                )
                                .onTapGesture {
                                    viewModel.selectTag(tag: tag)
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            withAnimation(.easeInOut) {
                                viewModel.expandOrCollapse()
                            }
                        } label: {
                            Text(viewModel.showAllTagsButtonTitle)
                        }
                        
                    }
                    .padding()
                    
                }
            }
            .toolbar { toolbarContent }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                applyButton
            }
        }
    }
}

// MARK: - Buttons

private extension FilesFilterView {
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
        .tint(ColorTheme.Base.primary.color)
        .wireTextStyle(.buttonBig)
        .padding()
    }
}

// MARK: - Toolbar

private extension FilesFilterView {
    
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { clearAllButton }
        ToolbarItem(placement: .topBarTrailing) { closeButton }
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
        .accessibilityIdentifier("close")
    }
    
}

// MARK: - Tags

private struct TagPill: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        Text(text)
            .foregroundStyle(isSelected ? ColorTheme.Base.primary.color : ColorTheme.Backgrounds.onSurface.color)
            .wireTextStyle(.body2)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? ColorTheme.Base.onPrimaryVariant.color.opacity(0.1)
                : ColorTheme.Backgrounds.surface.color
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                        ? ColorTheme.Base.onPrimaryVariant.color
                        : .clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
    }
}

#Preview {
    FilesFilterView(viewModel: .preview())
}
