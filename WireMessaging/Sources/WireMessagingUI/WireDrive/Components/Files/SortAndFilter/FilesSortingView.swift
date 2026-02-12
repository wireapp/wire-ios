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
                
                ForEach(viewModel.availableSortingKeys, id: \.self) { sortingKey in
                    Button {
                        viewModel.select(sortingKey: sortingKey)
                    } label: {
                        Label(
                            sortingKey.title,
                            systemImage: viewModel.sortingSelection.sortingKey == sortingKey ? "checkmark" : ""
                        )
                    }
                }
                
                Divider()
                
                ForEach(FilesSortingViewModel.SortingOrder.allCases, id: \.self) { sortingOrder in
                    Button {
                        viewModel.select(sortingOrder: sortingOrder)
                    } label: {
                        Label(
                            sortingOrder.title,
                            systemImage: viewModel.sortingSelection.sortingOrder == sortingOrder ? "checkmark" : ""
                        )
                    }
                }

            } label: {
                HStack(spacing: 5) {
                    Text(viewModel.sortingSelection.sortingKey.title)
                        .foregroundStyle(.primary)
                        .font(for: .h5)

                    Image(systemName: viewModel.sortingSelection.sortingOrder.iconName)
                        .resizable()
                        .frame(width: 9, height: 11)
                }.frame(minWidth: 120, alignment: .leading)
                
            }.foregroundStyle(.primary)
            
            Spacer()
            
            if !viewModel.isBrowsing {
                Text(Strings.results)
                    .font(for: .subline2)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
            }
        }.padding(.horizontal)
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
