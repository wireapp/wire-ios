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

struct FilesSortFilterView: View {
    @StateObject package var viewModel: FilesSortFilterViewModel

    package init(
        viewModel: @autoclosure @escaping () -> FilesSortFilterViewModel,
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(viewModel.queryOptions, id: \.self) { queryOption in
                    capsule(for: queryOption)
                }
            }
            .padding(.horizontal, 10)
        }
        .padding(.horizontal, -5)
    }

    @ViewBuilder
    private func capsule(for queryOption: FilesSortFilterViewModel.QueryOptions) -> some View {
        switch queryOption {
        case let .sorting(sorting):
            menuCapsule(sorting)
        case let .filtering(filters):
            buttonCapsule(filters)
        }
    }

    @ViewBuilder
    private func buttonCapsule(_ filters: [FilesSortFilterViewModel.QueryOptions.Filtering]) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

        ForEach(filters, id: \.self) { filter in
            Button {
                withAnimation {}
            } label: {
                HStack {
                    Text(viewModel.title(for: filter))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                }
                .fontWeight(.medium)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background {
                    shape.fill(ColorTheme.Backgrounds.backgroundVariant.color)
                }
                .background {
                    shape.stroke(ColorTheme.Base.secondaryText.color)
                }
                .padding(.vertical, 1)
            }
            //        .accessibilityLabel(Text(Accessibility.Tags.addTag.replacingOccurrences(of: "{0}", with: criterion)))
            .foregroundStyle(.primary)
        }

    }

    @ViewBuilder
    private func menuCapsule(_ sorting: FilesSortFilterViewModel.QueryOptions.Sorting) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

        Menu {
            ForEach(sorting.sortKey, id: \.self) { sortKey in
                Button {} label: {
                    Label(
                        viewModel.title(for: sortKey.key),
                        systemImage: sortKey.isSelected ? "checkmark" : ""
                    )
                }
            }

            Divider()

            ForEach(sorting.sortOrder, id: \.self) { sortOrder in
                Button {} label: {
                    Label(
                        viewModel.title(for: sortOrder.order),
                        systemImage: sortOrder.isSelected ? "checkmark" : ""
                    )
                }
            }

        } label: {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14, weight: .semibold))

                Text(viewModel.title(for: sorting))

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
            }
            .fontWeight(.medium)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                shape.fill(ColorTheme.Backgrounds.backgroundVariant.color)
            }
            .background {
                shape.stroke(ColorTheme.Base.secondaryText.color)
            }
            .padding(.vertical, 1)
        }.foregroundStyle(.primary)
    }
}

#Preview {
    FilesSortFilterView(viewModel: FilesSortFilterViewModel())
}
