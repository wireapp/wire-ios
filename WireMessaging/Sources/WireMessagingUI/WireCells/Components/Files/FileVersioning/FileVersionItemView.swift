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
import WireFoundation
import WireMessagingDomain
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct FileVersionItemView: View {
    @StateObject private var viewModel: FileVersionItemViewModel
    @Environment(\.wireAccentColor) private var wireAccentColor
    @State private var showRestoreVersionAlert = false

    init(
        viewModel: @autoclosure @escaping () -> FileVersionItemViewModel,
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Image(systemName: "arrow.trianglehead.counterclockwise")

                VStack(alignment: .leading) {
                    Text(viewModel.item.title)
                        .font(for: .body1)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                    Text(viewModel.item.subtitle)
                        .font(for: .h4)
                        .fontWeight(.regular)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)

                }.padding(.leading, 12)

                Spacer()

                Menu {
                    restoreButton
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                }
            }
        }
        .alert(
            Strings.FilesVersioning.restoreAlertTitle,
            isPresented: $showRestoreVersionAlert
        ) {
            Button(Strings.FilesVersioning.restoreAlertAction, role: .cancel) {
                Task { await viewModel.restore() }
            }
            Button(L10n.Localizable.General.cancel) {}
        } message: {
            Text(Strings.FilesVersioning.restoreAlertMessage)
        }
        .contentShape(Rectangle())
    }

    private var restoreButton: some View {
        Button(
            action: {
                showRestoreVersionAlert = true
            }, label: {
                HStack {
                    Text(Strings.FilesVersioning.restoreAlertTitle)

                    Image(systemName: "arrow.uturn.left")
                        .foregroundStyle(SemanticColors.Icon.foregroundDefaultBlack.color)
                }

            }
        )
    }

}

#Preview {
    FileVersioningView(viewModel: .preview())
}
