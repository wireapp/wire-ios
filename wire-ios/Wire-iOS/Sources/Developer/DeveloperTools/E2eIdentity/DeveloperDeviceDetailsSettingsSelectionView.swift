//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

struct DeveloperDeviceDetailsSettingsSelectionView: View {

    // MARK: - Properties
    @StateObject
    var viewModel: DeveloperDeviceDetailsSettingsSelectionViewModel

    // MARK: - Views

    var body: some View {
        Toggle("Enable E2eIdentity", isOn: $viewModel.isE2eIdentityViewEnabled)
        Divider()
        List(viewModel.sections, rowContent: sectionView(for:))
            .navigationTitle("E2eIdentity Details Selection View")
            .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionView(for section: DeveloperDeviceDetailsSettingsSelectionViewModel.Section) -> some View {
        Section {
            ForEach(section.items, content: itemView(for:))
        } header: {
        }
    }

    @ViewBuilder
    private func itemView(for item: DeveloperDeviceDetailsSettingsSelectionViewModel.Item) -> some View {
        HStack {
            Text(item.title)
            Spacer()

            if viewModel.selectedItemID == item.id {
                Image(systemName: "checkmark")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            viewModel.handleEvent(.itemTapped(item))
        }
    }
}
