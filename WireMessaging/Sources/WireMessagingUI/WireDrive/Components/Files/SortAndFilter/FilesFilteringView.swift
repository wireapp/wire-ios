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

private typealias Strings = L10n.Localizable.Conversation.WireCells.Filtering

struct FilesFilteringView: View {
    @StateObject package var viewModel: FilesFilteringViewModel
    @Environment(\.wireAccentColor) private var accentColor
    
    @ScaledMetric var dropDownIconWidth: CGFloat = 8
    @ScaledMetric var dropDownIconHeight: CGFloat = 4

    package init(
        viewModel: @autoclosure @escaping () -> FilesFilteringViewModel,
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.availableFilters, id: \.self) { filter in
                    Button {
                        viewModel.select(filter: filter)
                    } label: {
                        capsule(for: filter)
                    }
                }
                
                if shouldShowRemoveFilters {
                    Button {
                        viewModel.removeAllFilters()
                    } label: {
                        Text(Strings.removeAllFilters)
                            .font(for: .h5)
                            .foregroundStyle(ColorTheme.Base.primary(accentColor).color)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.horizontal)
        }
        .sheet(
            item: $viewModel.sheetNavigation,
            onDismiss: {},
            content: { navigationItem in
                sheet(for: navigationItem)
                    .presentationDetents([.medium])
            }
        )
    }

    @ViewBuilder
    private func sheet(for navigationItem: FilesFilteringViewModel.SheetNavigation) -> some View {
        switch navigationItem {
        case .tags:
            FilesFilterBy.TagsView(
                fetchTagsUseCase: viewModel.useCases.fetchTagsUseCase,
                selectedItems: viewModel.filtersSelection.tags,
                onApply: { selectedItems in
                    viewModel.filtersSelection.tags = selectedItems
                }
            )
        case .types:
            FilesFilterBy.TypeView(
                includeFolders: !viewModel.isBrowsing,
                selectedItems: viewModel.filtersSelection.types,
                onApply: { selectedItems in
                    viewModel.filtersSelection.types = selectedItems
                }
            )
        case .conversations:
            FilesFilterBy.ConversationView(
                availableItems: viewModel.conversations,
                selectedItems: viewModel.filtersSelection.conversations,
                onApply: { selectedItems in
                    viewModel.filtersSelection.conversations = selectedItems
                }
            )
        case .owners:
            FilesFilterBy.OwnerView(
                availableItems: viewModel.conversationsParticipants,
                selectedItems: viewModel.filtersSelection.owners,
                onApply: { selectedItems in
                    viewModel.filtersSelection.owners = selectedItems
                }
            )
        }
    }
    
    @ViewBuilder
    private func capsule(for filter: FilesFilteringViewModel.Filtering) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        
        HStack(alignment: .center, spacing: 5) {
            Text(filter.title)
                .font(for: .h5)
                .foregroundStyle(textColor(for: filter))

            if let badge = viewModel.badge(for: filter) {
                Text(badge)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        ColorTheme.Base.primary(accentColor).color,
                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )
            }

            Image(systemName: "arrowtriangle.down.fill")
                .resizable()
                .frame(width: dropDownIconWidth, height: dropDownIconHeight)
                .foregroundStyle(imageColor(for: filter))
        }
        .fontWeight(.semibold)
        .padding(8)
        .background {
            shape.fill(capsuleFillColor(for: filter))
        }
        .overlay {
            shape.strokeBorder(
                capsuleStrokeColor(for: filter),
                lineWidth: 1
            )
        }
        .padding(.vertical, 1)
    }

    // MARK: - Helpers

    private func imageColor(for filter: FilesFilteringViewModel.Filtering) -> Color {
        if viewModel.isFilterSelected(filter) {
            ColorTheme.Base.primary(accentColor).color
        } else {
            .primary
        }
    }

    private func textColor(for filter: FilesFilteringViewModel.Filtering) -> Color {
        viewModel.isFilterSelected(filter) ? ColorTheme.Base.primary(accentColor).color : .primary
    }

    private func capsuleFillColor(for filter: FilesFilteringViewModel.Filtering) -> Color {
        if viewModel.isFilterSelected(filter) {
            ColorTheme.Base.primary(accentColor).color.opacity(0.1)
        } else {
            ColorTheme.Backgrounds.surface.color
        }
    }

    private func capsuleStrokeColor(for filter: FilesFilteringViewModel.Filtering) -> Color {
        if viewModel.isFilterSelected(filter) {
            ColorTheme.Base.primary(accentColor).color
        } else {
            ColorTheme.Buttons.Secondary.disabledOutline.color
        }
    }

    private var shouldShowRemoveFilters: Bool {
        viewModel.filtersSelection.hasFilterSelected
    }
}

#Preview {
    FilesFilteringView(
        viewModel: .preview(isBrowsing: false)
    )
}
