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

private typealias Strings = L10n.Localizable.Conversation.WireCells.Sorting

struct FilesSortingView: View {
    @StateObject package var viewModel: FilesSortingViewModel
    
    @ScaledMetric private var defaultSortMenuIconWidth: CGFloat = 12
    @ScaledMetric private var defaultSortMenuIconHeight: CGFloat = 10
    @ScaledMetric private var selectedSortMenuIconWidth: CGFloat = 9
    @ScaledMetric private var selectedSortMenuIconHeight: CGFloat = 11

    package init(
        viewModel: @autoclosure @escaping () -> FilesSortingViewModel,
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        HStack {
            Menu {
                Text(Strings.title)
                    .font(for: .h5)
                    .foregroundStyle(.secondary)

                Divider()

                ForEach(FilesSortingViewModel.SortingKey.allCases, id: \.self) { sortingKey in
                    let isSelected = viewModel.sortingSelection.sortingKey == sortingKey
                        
                    Button {
                        viewModel.select(sortingKey: sortingKey)
                    } label: {
                        Label(
                            sortingKey.title,
                            systemImage: selectionIconName(isSelected: isSelected)
                        )
                    }
                }

                Divider()

                ForEach(viewModel.sortingOrders, id: \.self) { sortingOrder in
                    let isSelected = viewModel.sortingSelection.sortingOrder == sortingOrder
                    
                    Button {
                        viewModel.select(sortingOrder: sortingOrder)
                    } label: {
                        Label(
                            sortingOrder.title(forKey: viewModel.sortingSelection.sortingKey ?? .date),
                            systemImage: selectionIconName(isSelected: isSelected)
                        )
                    }
                }

            } label: {
                HStack(spacing: 5) {
                    Text(viewModel.menuLabel)
                        .foregroundStyle(.primary)
                        .font(for: .h5)

                    menuIcon()
                }
            }
            .foregroundStyle(.primary)

            Spacer()

            if !viewModel.isBrowsing {
                Text(Strings.results)
                    .font(for: .subline2)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func menuIcon() -> some View {
        if let name = viewModel.sortingSelection.sortingOrder?.iconName {
            Image(systemName: name)
                .resizable()
                .frame(width: selectedSortMenuIconWidth, height: selectedSortMenuIconHeight)
        } else {
            Image(systemName: "arrow.up.arrow.down")
                .resizable()
                .frame(width: defaultSortMenuIconWidth, height: defaultSortMenuIconHeight)
        }
    }
    
    private func selectionIconName(isSelected: Bool) -> String {
        isSelected ? "checkmark" : ""
    }
}

#Preview {
    FilesSortingView(
        viewModel: FilesSortingViewModel(
            isBrowsing: false,
            onUpdate: { _ in }
        )
    )
}
