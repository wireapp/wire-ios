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
import WireDesign

struct FilesViewItemView: View {

    @StateObject private var viewModel: FilesItemViewModel
    @ScaledMetric private var imageHeight: CGFloat = 28

    init(viewModel: @autoclosure @escaping () -> FilesItemViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {

                Image(viewModel.icon.resource)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: imageHeight)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.fileName)
                        .wireTextStyle(.body2)
                        .lineLimit(1)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                    Text(viewModel.subtitle ?? "")
                        .wireTextStyle(.subline1)
                        .lineLimit(1)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                }
                .padding(.vertical, 8)

                Spacer()

                Menu {
                    if !viewModel.isDownloaded {
                        Button(action: download) {
                            Label(Strings.Files.Item.Menu.download, systemImage: "square.and.arrow.down.fill")
                        }
                    }

                    Button(action: rename) {
                        Label(Strings.Files.Item.Menu.rename, systemImage: "pencil")
                    }

                    Button(role: .destructive, action: delete) {
                        Label(Strings.Files.Item.Menu.delete, systemImage: "trash.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                }
                .padding(.all, 8)
            }
            Divider()
        }
    }

    private func download() {
        // FIXME: [WPB-19436] Implement
    }

    private func rename() {
        // FIXME: [WPB-19393] Implement
    }

    private func delete() {
        // FIXME: [WPB-19392] Implement
    }

}
