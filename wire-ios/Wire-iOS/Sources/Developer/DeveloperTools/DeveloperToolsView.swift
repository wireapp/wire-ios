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

import Inject
import SwiftUI

struct DeveloperToolsView: View {

    // MARK: - Properties

    @StateObject
    var viewModel: DeveloperToolsViewModel

    @ObserveInjection var inject

    // MARK: - Views

    var body: some View {
        List(viewModel.sections, rowContent: sectionView(for:))
            .navigationTitle(Text(verbatim: "Developer tools"))
            .navigationBarItems(trailing: dismissButton)
            .alert(isPresented: $viewModel.isPresentingAlert) {
                Alert(
                    title: Text(viewModel.alertTitle ?? ""),
                    message: Text(viewModel.alertBody ?? "")
                )
            }.enableInjection()
    }

    private func sectionView(for section: DeveloperToolsViewModel.Section) -> some View {
        Section {
            ForEach(section.items, content: itemView(for:))
        } header: {
            Text(section.header)
        }
    }

    @ViewBuilder
    private func itemView(for item: DeveloperToolsViewModel.Item) -> some View {
        switch item {
        case let .button(buttonItem):
            Button {
                viewModel.handleEvent(.itemTapped(item))
            } label: {
                Text(buttonItem.title)
            }

        case let .text(textItem):
            TextItemCell(title: textItem.title, value: textItem.value)
                .contextMenu {
                    Button(
                        hapticFeedbackStyle: .success,
                        action: {
                            viewModel.handleEvent(.itemCopyRequested(item))
                        },
                        label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    )
                }

        case let .destination(destinationItem):
            NavigationLink(destinationItem.title, destination: destinationItem.makeView)

        }
    }

    private var dismissButton: some View {
        Button(
            action: { viewModel.handleEvent(.dismissButtonTapped) },
            label: { Text(verbatim: "Close") }
        )
    }

}

// MARK: - Subviews

private struct TextItemCell: View {

    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Previews

struct DeveloperToolsView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationView {
            DeveloperToolsView(viewModel: DeveloperToolsViewModel())
        }
    }
}
