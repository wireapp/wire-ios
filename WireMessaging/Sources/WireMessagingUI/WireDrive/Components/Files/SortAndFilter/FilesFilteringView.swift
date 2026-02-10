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

struct FilesFilteringView: View {
    @StateObject package var viewModel: FilesFilteringViewModel
    @Environment(\.wireAccentColor) private var accentColor

    package init(
        viewModel: @autoclosure @escaping () -> FilesFilteringViewModel,
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(viewModel.availableFilters, id: \.self) { filter in
                    capsule(for: filter)
                        .onTapGesture {
                            viewModel.select(filter: filter)
                        }
                }
            }
        }
        .padding(.horizontal, -5)
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
            FilesFilterByTagsView(
                fetchTagsUseCase: viewModel.useCases.fetchTagsUseCase,
                selectedItems: viewModel.filtersSelection.tags,
                onApply: { selectedTags in
                    viewModel.filtersSelection.tags = Set(selectedTags.map(\.self))
                }
            )
        case .types:
            FilesFilterByTypeView(
                selectedItems: viewModel.filtersSelection.types,
                includeFolders: true, //TODO: should be true for specific conversations and false for "all conversations"
                onApply: { selectedTypes in
                    viewModel.filtersSelection.types = selectedTypes
                }
            )
        case .conversations:
            Text("Conversations")
        case .owners:
            Text("Owners")
        }
    }
    
    @ViewBuilder
    private func capsule(for filter: FilesFilteringViewModel.Filtering) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        HStack(alignment: .center, spacing: 6) {
            Text(filter.title)
                .foregroundStyle(textColor(for: filter))

            if let badge = viewModel.badge(for: filter) {

                Text(badge)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        ColorTheme.Base.primary(accentColor).color,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            }

            if let iconName = iconName(for: filter) {
                Image(systemName: iconName)
                    .if(filter != .sharedByMe) { view in
                        view.resizable()
                            .frame(width: 10, height: 5)
                            .rotationEffect(.degrees(180))
                        
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(imageColor(for: filter))
            }
        }
        .fontWeight(.semibold)
        .padding(8)
        .if(filter != .removeAllFilters) { view in
            view.background {
                shape.fill(capsuleFillColor(for: filter))
                shape.stroke(capsuleStrokeColor(for: filter))
            }
        }
        .padding(.vertical, 1)
        .opacity(opacity(for: filter))
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
        switch filter {
        case .removeAllFilters:
            ColorTheme.Base.primary(accentColor).color
        default:
            viewModel.isFilterSelected(filter) ? ColorTheme.Base.primary(accentColor).color : .primary
        }
    }

    private func iconName(for filter: FilesFilteringViewModel.Filtering) -> String? {
        switch filter {
        case .removeAllFilters:
            nil
        case .sharedByMe:
            viewModel.isFilterSelected(filter) ? "xmark" : nil
        default:
            "triangle.fill"
        }
    }

    private func opacity(for filter: FilesFilteringViewModel.Filtering) -> Double {
        (filter == .removeAllFilters && shouldShowRemoveFilters) || filter != .removeAllFilters ? 1 : 0
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
