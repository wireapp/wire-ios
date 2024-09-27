//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - SwitchBackendView

struct SwitchBackendView: View {
    // MARK: - Properties

    @StateObject var viewModel: SwitchBackendViewModel

    // MARK: - Views

    var body: some View {
        List(viewModel.items, rowContent: itemView(for:))
            .navigationTitle("Switch backend")
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $viewModel.alertItem) { alertItem in
                Alert(
                    title: Text(""),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text("OK")) { alertItem.action?() }
                )
            }
    }

    @ViewBuilder
    private func itemView(for item: SwitchBackendViewModel.Item) -> some View {
        HStack {
            Text(item.title)
            Spacer()

            if viewModel.selectedItemID == item.id {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.handleEvent(.itemTapped(item))
        }
    }
}

// MARK: - SwitchBackendView_Previews

struct SwitchBackendView_Previews: PreviewProvider {
    static var previews: some View {
        SwitchBackendView(viewModel: SwitchBackendViewModel())
    }
}
