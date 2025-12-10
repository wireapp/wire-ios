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

// MARK: - MoveToFolderView

struct MoveToFolderView<ViewModel>: View where ViewModel: MoveToFolderViewModelProtocol {

    @StateObject private var viewModel: ViewModel

    package init(viewModel: @autoclosure @escaping () -> ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            viewModel.makeView(path: viewModel.rootPath)
                .navigationDestination(for: MoveToFolderViewModel.FilesNavigationItem.self) { navigationItem in
                    viewModel.makeView(path: navigationItem.path)
                }
        }
    }
}

// MARK: - Previews

#Preview("Stack Navigation") {
    MoveToFolderView(
        viewModel: MockMoveToFolderViewModel(containerPath: "a/b/c/d/e")
    )
}
