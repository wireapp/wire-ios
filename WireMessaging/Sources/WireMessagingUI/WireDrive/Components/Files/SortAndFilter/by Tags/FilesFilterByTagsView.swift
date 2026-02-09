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
import WireDesign
import WireFoundation

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct FilesFilterByTagsView: View {
    @Environment(\.wireAccentColor) private var wireAccentColor
    @Environment(\.dismiss) private var dismiss
    
    @StateObject package var viewModel: ViewModel
    
    let onApply: (Set<String>) -> ()

    package init(
        viewModel: @autoclosure @escaping () -> ViewModel,
        onApply: @escaping (Set<String>) -> ()
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            content()
                .background {
                    ColorTheme.Backgrounds.background.color
                        .ignoresSafeArea(.all)
                }
                .toolbar { toolbarContent }
                .navigationTitle(Strings.Filter.Tags.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .alert(L10n.Localizable.General.failure, isPresented: $viewModel.showError) {
                    Button(L10n.Localizable.General.confirm, role: .cancel) {}
                }
                .overlay { if viewModel.isLoading { ProgressView() } }
                .searchable(text: $viewModel.searchText, prompt: Strings.Filter.Tags.searchPrompt)
        }
    }
    
    @ViewBuilder private func content() -> some View {
        VStack {
            ScrollView {
                tagsView
                    .padding()
            }
            
            removeFilterButton
                .padding(10)
        }
    }
}

// MARK: - Tags

private extension FilesFilterByTagsView {
    var tagsViewSpacing: CGFloat {
        viewModel.presentedTags.isEmpty ? 0 : 20
    }
    
    var tagsView: some View {
        VStack(alignment: .leading, spacing: tagsViewSpacing) {
            if viewModel.presentedTags.isEmpty {
                Spacer()
                
                Text(viewModel.searchText.isEmpty ? Strings.Filter.Tags.emptyTitle : Strings.Filter.Tags.notFoundBySearch)
                    .font(for: .h4)
                    .padding([.top, .bottom])
                
                Spacer()
            }
            
            FlowLayout(spacing: 14, alignment: .leading) {
                ForEach(viewModel.presentedTags, id: \.self) { tag in
                    TagPill(
                        text: tag,
                        isSelected: viewModel.isTagSelected(tag)
                    )
                    .onTapGesture {
                        viewModel.selectTag(tag)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeInOut.speed(1.5), value: viewModel.selectedTags)
        }
    }
}

private extension FilesFilterByTagsView {
    struct TagPill: View {
        @Environment(\.wireAccentColor) private var wireAccentColor
        
        let text: String
        let isSelected: Bool

        var body: some View {
            HStack(spacing: 6) {
                Text(text)
                
                if isSelected {
                    Image(systemName: "xmark")
                }
            }
            .foregroundStyle(
                isSelected
                    ? ColorTheme.Base.primary(wireAccentColor).color
                    : ColorTheme.Backgrounds.onSurface.color
            )
            .font(for: .h4)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? ColorTheme.Base.primaryVariant(wireAccentColor).color
                    : ColorTheme.Backgrounds.surface.color
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected
                            ? ColorTheme.Base.primary(wireAccentColor).color
                            : .clear,
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
        }
    }
}

// MARK: - Toolbar

private extension FilesFilterByTagsView {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { closeButton }
        ToolbarItem(placement: .topBarTrailing) { saveButton }
    }
}

// MARK: - Buttons

private extension FilesFilterByTagsView {
    var saveButton: some View {
        Button {
            Task {
                onApply(viewModel.selectedTags)
                dismiss()
            }
        } label: {
            Text(L10n.Localizable.General.save)
                .fontWeight(.semibold)
                .accessibilityIdentifier("saveButton")
        }
        .disabled(!viewModel.hasChanges)
    }

    var removeFilterButton: some View {
        Button {
            Task { await viewModel.clearAll() }
        } label: {
            Text(Strings.Filter.removeFilter)
        }
        .accessibilityIdentifier("removeFilterButton")
        .disabled(viewModel.selectedTags.isEmpty)
    }

    var closeButton: some View {
        Button(
            action: { dismiss() },
            label: {
                Text(L10n.Localizable.General.cancel)
            }
        )
        .accessibilityIdentifier("cancelButton")
    }
}

#Preview {
    FilesFilterByTagsView(viewModel: .preview()) { tags in }
}
