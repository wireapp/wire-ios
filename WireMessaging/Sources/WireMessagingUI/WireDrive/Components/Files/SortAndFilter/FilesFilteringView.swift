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

    package init(
        viewModel: @autoclosure @escaping () -> FilesFilteringViewModel,
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(FilesFilteringViewModel.Filtering.allCases, id: \.self) { filter in
                    capsule(for: filter)
                }
            }
            .padding(.horizontal, 10)
        }
        .padding(.horizontal, -5)
    }

    @ViewBuilder
    private func capsule(for filter: FilesFilteringViewModel.Filtering) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

        HStack {
            Text(filter.title)
                .foregroundStyle(filter == .removeAllFilters ? ColorTheme.Buttons.Primary.enabled.color : .primary)

            if filter != .removeAllFilters {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .fontWeight(.medium)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .if(filter != .removeAllFilters) { view in
            view.background {
                shape.fill(capsuleFillColor(for: filter))
                shape.stroke(capsuleStrokeColor(for: filter))
            }
        }
        .padding(.vertical, 1)
        .opacity(
            (filter == .removeAllFilters && shouldShowRemoveFilters) || filter != .removeAllFilters ? 1 : 0
        )
    }

    private func capsuleFillColor(for filter: FilesFilteringViewModel.Filtering) -> Color {
        if viewModel.isFilterSelected(filter) {
            ColorTheme.Base.onPrimaryVariant.color
        } else {
            ColorTheme.Backgrounds.backgroundVariant.color
        }
    }

    private func capsuleStrokeColor(for filter: FilesFilteringViewModel.Filtering) -> Color {
        if viewModel.isFilterSelected(filter) {
            ColorTheme.Base.onPrimaryVariant.color
        } else {
            ColorTheme.Base.secondaryText.color
        }
    }

    private var shouldShowRemoveFilters: Bool {
        viewModel.filtersSelection.hasFilterSelected
    }
}

#Preview {
    FilesFilteringView(viewModel: FilesFilteringViewModel())
}
